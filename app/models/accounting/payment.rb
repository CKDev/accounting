module Accounting
  class Payment < ::ActiveRecord::Base

    include AccountingHelper

    belongs_to :profile, inverse_of: :payments, required: true

    has_one :address, inverse_of: :payment, autosave: true, dependent: :destroy

    before_destroy :delete_payment, if: proc { |p| p.profile.present? }

    after_create :reset_default

    after_destroy :reset_default, if: proc { |p| p.profile.present? }

    attr_accessor :month, :year

    attr_accessor :routing, :account, :bank_name, :account_holder, :account_type, :check_number, :echeck_type

    enum account_type: [:checking, :savings, :businessChecking]

    enum profile_type: [:card, :ach]

    before_validation :format_data

    validates :address, presence: true, if: :card?, on: :create

    validates :account_type, inclusion: { in: Accounting::Payment.account_types.keys }, if: :ach?

    validates :month, :year, presence: true, if: :card?

    validates :month, :year, numericality: { only_integer: true }, if: :card?

    validates :routing, :account, :bank_name, :account_holder, :account_type, presence: true, if: :ach?

    validates :profile_type, presence: true, inclusion: { in: Accounting::Payment.profile_types.keys }

    validate :expiration_date, on: :create, if: :card?

    validate :create_payment, if: proc { |p| p.payment_profile_id.blank? }, unless: :card?

    # The below validation should not be run if errors exist, since the above :create_payment validation sets these values
    validates_presence_of :payment_profile_id, if: proc { |p| p.errors.blank? }

    accepts_nested_attributes_for :address, reject_if: :all_blank

    delegate :accountable, to: :profile

    def details
      request = GetCustomerPaymentProfileRequest.new
      request.customerProfileId = profile.profile_id
      request.customerPaymentProfileId = payment_profile_id

      @response ||= authnet(:api).get_customer_payment_profile(request)

      if @response.messages.resultCode == MessageTypeEnum::Ok
        @response.paymentProfile
      else
        nil
      end
    end

    def default!
      if profile.present? && !profile.destroyed?
        profile.payments.where(default: true).update_all(default: false)
        update_attribute(:default, true)
      end
    end

    private

      def create_payment
        # Don't bother creating the payment if errors exist on self or the address at this point, it will fail to validate anyways
        return if errors.present? || (address.present? && address.errors.present?)

        response = authnet(:api).create_customer_payment_profile(create_request)

        unless response == nil || response.is_a?(Exception)
          if response.messages.resultCode == MessageTypeEnum::Ok
            if response.validationDirectResponse.present?
              # Add the payment attributes. Expiration only applies to card payment types
              # If no payment types exist yet, make the first one the default
              assign_attributes(
                title: response.validationDirectResponse.split(',')[51],
                payment_profile_id: response.customerPaymentProfileId,
                default: profile.payments.count == 0,
                last_four: response.validationDirectResponse.split(',')[50].to_s[-4..-1]
              )
            end
          else
            # All is not well, include the authorize.net error code and message
            self.errors.add(:base, [response.messages.messages[0].code, response.messages.messages[0].text].join(' '))
          end
        else
          self.errors.add(:base, ['Null Response', 'Failed to create a new customer payment profile.'].join(' '))
        end
      end

      # Delete the associated payment profile on Authorize.net when this instance is destroyed
      def delete_payment
        request = DeleteCustomerPaymentProfileRequest.new(nil, nil, payment_profile_id, profile.profile_id)
        authnet(:api).delete_customer_payment_profile(request)
      end

      def reset_default
        if profile.payments.where(default: true).count.zero?
          profile.payments.first.try(:default!)
        end
      end

      def expiration_date
        # Year and month are -1 if the payment is being synched from an authorize webhook.
        return if year == -1 && month == -1

        self.errors.add(:base, 'Expiration date cannot be in the past') unless Time.new(year.to_i, month.to_i, Time.now.day, Time.now.hour, Time.now.min, 0) > Time.now
      rescue ArgumentError
        self.errors.add(:base, 'Expiration date is invalid')
      end

      def format_data
        # Year and month are -1 if the payment is being synched from an authorize webhook.
        return if year == -1 && month == -1

        # Ensure the year is 4 digit representation
        self.year = '20' + year.to_s[-2..-1].to_s
        self.expiration = Date.new(year.to_i, month.to_i, -1) rescue nil
      end

      def create_request
        # Build the payment object
        payment = PaymentType.new
        payment.bankAccount = BankAccountType.new
        payment.bankAccount.accountType = account_type
        payment.bankAccount.routingNumber = routing
        payment.bankAccount.accountNumber = account
        payment.bankAccount.nameOnAccount = account_holder
        payment.bankAccount.echeckType = echeck_type || AuthorizeNet::ECheck::CheckType::INTERNET_INITIATED
        payment.bankAccount.bankName = bank_name
        payment.bankAccount.checkNumber = check_number

        # Build an address object
        billTo = address&.to_billing_address

        # Use the previously defined payment and billTo objects to
        # build a payment profile to send with the request
        paymentProfile = CustomerPaymentProfileType.new
        paymentProfile.payment = payment
        paymentProfile.billTo = billTo
        paymentProfile.defaultPaymentProfile = true

        # Build the request object
        request = CreateCustomerPaymentProfileRequest.new
        request.paymentProfile = paymentProfile
        request.customerProfileId = profile.profile_id
        request.validationMode = api_validation_mode(profile.accountable)
        request
      end

  end
end
