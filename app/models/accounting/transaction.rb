module Accounting
  class Transaction < ::ActiveRecord::Base

    include AccountingHelper

    belongs_to :profile, inverse_of: :transactions

    belongs_to :payment, optional: true

    belongs_to :original_transaction, optional: true, class_name: '::Accounting::Transaction'

    belongs_to :subscription, optional: true

    serialize :options, Hash

    delegate :accountable, to: :profile

    # Holds
    scope :holds, -> { where(transaction_type: :auth_only) }

    # Captures
    scope :captures, -> { where(transaction_type: :prior_auth_capture) }

    # Voids
    scope :voids, -> { where(transaction_type: :void) }

    # Charges
    scope :charges, -> { where(transaction_type: :auth_capture) }

    # Refunds
    scope :refunds, -> { where(transaction_type: :refund) }

    enum status: [:pending, :voided, :expired, :declined, :returned, :held, :fraud, :captured, :refunded, :error, :duplicate]

    validates :transaction_type, inclusion: { in: %w(auth_only prior_auth_capture void auth_capture refund) }

    validates :payment, presence: true, if: proc { |t| ['auth_only', 'auth_capture', 'refund'].include?(t.transaction_type) }

    validates :amount, numericality: { greater_than: 0 }, if: proc { |t| t.transaction_type != 'void' }

    validates :payment, presence: true, if: proc { |t| !['void', 'prior_auth_capture'].include?(t.transaction_type) }

    validate :can_capture, if: proc { |t| t.transaction_type == 'prior_auth_capture' }

    validate :can_refund, if: proc { |t| t.transaction_type == 'refund' }

    validate :can_void, if: proc { |t| t.transaction_type == 'void' }

    after_commit :process_later

    before_save :update_subscription!

    delegate :accountable, to: :profile, allow_nil: true # Accountable might not exist before sync.

    def details(api_opts={})
      request = GetTransactionDetailsRequest.new
      request.transId = transaction_id

      @response ||= authnet(:api, api_opts).get_transaction_details(request)
      if @response && @response.messages.resultCode == MessageTypeEnum::Ok
        @response.transaction
      else
        nil
      end
    end

    def subscription?
      subscription.present?
    end

    def process_now
      begin
        process_now!
      rescue Accounting::DuplicateError => e
        Accounting.log('Transaction', 'Process', e.message)
        update(status: :duplicate, submitted_at: Time.now, message: e.message)
        self
      rescue => e
        update(message: e.message)
        self.errors.add(:base, e.message)
        false
      end
    end

    def process_now!
      accountable.try(:run_hook, :before_transaction_submit, self)

      return self if processed?

      begin
        case transaction_type
          when 'auth_only';          hold
          when 'prior_auth_capture'; capture
          when 'void';               void
          when 'auth_capture';       charge
          when 'refund';             refund
        end
      rescue Accounting::DuplicateError => e
        update(status: :duplicate, submitted_at: Time.now, message: e.message)
        raise e
      rescue StandardError => e
        update(status: :error, submitted_at: Time.now, message: e.message)
        raise e
      end

      # Flag a job id so that process_later does not unintentionally create a job, but only if it's not already set
      # This method is what is called within the Job
      update_column(:job_id, '0') unless job_id.present?

      accountable.try(:run_hook, :after_transaction_submit, self)

      self
    end

    def process_later
      unless job_id.present?
        job = Accounting::TransactionJob.set(queue: queue).perform_later(self)
        update_column(:job_id, job.provider_job_id)
      end
      self
    end

    def processed?
      submitted_at.present?
    end

    def refundable?
      return false unless (captured? && settled?)
      return false if submitted_at < Time.zone.now - 120.days
      true
    end

    def voidable?
      return false unless (captured? && !settled?)
      true
    end

    def sync!
      # TODO: I think this should update our db with any differing info from Authorize, but
      # I'm not sure that's the best thing to do at this point.  For now, just update settled
      # status.
      update_column(:settled, true) if details&.transactionStatus == 'settledSuccessfully'
    end

    private

      def handle_transaction(response, **params)
        if response.present? && !response.is_a?(Exception)
          if response.messages.resultCode == MessageTypeEnum::Ok
            if response.transactionResponse&.messages.present?
              fields = {
                submitted_at: Time.now.utc,
                transaction_method: trans_method(response),
                authorization_code: response.transactionResponse.authCode,
                transaction_id: response.transactionResponse.transId,
                avs_response: response.transactionResponse.avsResultCode
              }

              assign_attributes(params.merge(fields))
              return save
            else
              if response&.transactionResponse&.errors.present?
                error_msg = [response.transactionResponse.errors.errors[0].errorCode, response.transactionResponse.errors.errors[0].errorText].join(' ')
              end
            end
          else
            if response.transactionResponse&.errors.present?
              if response.transactionResponse.responseCode == '3' && response.transactionResponse.errors.errors[0].errorCode == '11'
                raise Accounting::DuplicateError, 'Transaction has already been submitted'
              end
              error_msg = [response.transactionResponse.errors.errors[0].errorCode, response.transactionResponse.errors.errors[0].errorText].join(' ')
            else
              error_msg = [response.messages.messages[0].code, response.messages.messages[0].text].join(' ')
            end
          end
        end

        error_msg ||= 'Failed to charge customer profile.'
        raise StandardError, HTMLEntities.new.decode(error_msg)
      end

      def trans_method(response)
        response.transactionResponse.accountType === 'eCheck' ? 'ECHECK' : 'CC'
      end

      def hold
        before_transaction!
        request = create_request(TransactionTypeEnum::AuthOnlyTransaction, amount, profile.profile_id, payment.payment_profile_id)
        response = authnet(:api).create_transaction(request)
        handle_transaction(response, status: :held, message: options[:message])
      end

      def capture
        before_transaction!
        request = create_request(TransactionTypeEnum::PriorAuthCaptureTransaction, amount, nil, nil, original_transaction.try(:transaction_id))
        response = authnet(:api).create_transaction(request)
        handle_transaction(response, status: :captured, message: options[:message])
      end

      def void
        before_transaction!
        request = create_request(TransactionTypeEnum::VoidTransaction, nil, nil, nil, original_transaction.try(:transaction_id))
        response = authnet(:api).create_transaction(request)
        handle_transaction(response, status: :voided, message: options[:message])
      end

      def charge
        before_transaction!
        request = create_request(TransactionTypeEnum::AuthCaptureTransaction, amount, profile.profile_id, payment.payment_profile_id)
        response = authnet(:api).create_transaction(request)
        handle_transaction(response, status: :captured, message: options[:message])
      end

      def refund
        before_transaction!
        request = create_request(TransactionTypeEnum::RefundTransaction, amount, profile.profile_id, payment.payment_profile_id, original_transaction.try(:transaction_id))
        response = authnet(:api).create_transaction(request)
        handle_transaction(response, status: :refunded, message: options[:message])
      end

      def before_transaction!
        raise Accounting::DuplicateError, 'Transaction has already been submitted' if processed?
      end

      def can_capture
        # Original transaction in this context should be a held transaction
        self.errors.add(:base, 'cannot be captured because it is not a hold') unless original_transaction.try(:held?)
        self.errors.add(:base, 'cannot be captured because the hold has expired') if original_transaction.try(:expired?)
      end

      def can_refund
        self.errors.add(:base, 'cannot be refunded because the transaction has not been captured') unless original_transaction.try(:captured?)
        self.errors.add(:amount, 'cannot be greater than the original transaction amount') if original_transaction.try(:captured?) && amount > (original_transaction.try(:amount) || 0)
      end

      def can_void
        self.errors.add(:base, 'cannot be voided because it has not been captured') unless original_transaction.try(:captured?)
        self.errors.add(:base, 'cannot be voided because it has settled') if original_transaction.try(:settled?)
      end

      def queue
        option(:queue, accountable) || :default
      end

      def update_subscription!
        subscription.update!(next_transaction_at: subscription.next_transaction_date) if subscription?
      end

      def create_request(type, amount, profile_id, payment_id, ref_trans_id=nil)
        request = CreateTransactionRequest.new
  
        request.transactionRequest = TransactionRequestType.new
        request.transactionRequest.amount = amount
        request.transactionRequest.transactionType = type
        request.transactionRequest.poNumber = options[:po_num]
        if profile_id.present? && payment_id.present?
          request.transactionRequest.profile = CustomerProfilePaymentType.new
          request.transactionRequest.profile.customerProfileId = profile_id
          request.transactionRequest.profile.paymentProfile = PaymentProfile.new(payment_id)
        end

        # Refund/Void
        request.transactionRequest.refTransId = ref_trans_id

        request
      end

  end
end
