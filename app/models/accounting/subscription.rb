module Accounting
  class Subscription < ::ActiveRecord::Base

    include AccountingHelper

    include AuthorizeNet::ARB::Subscription::Status

    include AuthorizeNet::ARB::Subscription::IntervalUnits

    belongs_to :profile, inverse_of: :subscriptions

    belongs_to :payment, optional: true

    has_many :transactions

    before_destroy :cancel_subscription, if: proc { Accounting.config.cancel_subscription_on_destroy }

    delegate :accountable, to: :profile

    enum status: [:pending, :duplicate, ACTIVE, EXPIRED, SUSPENDED, CANCELED, TERMINATED]

    validates_inclusion_of :status, in: Accounting::Subscription.statuses.keys

    validates :name, :start_date, :payment, :length, presence: true

    validates_inclusion_of :length, in: 7..365, message: 'interval must be between 7 and 365 days', if: proc { |s| s.unit == DAY }

    validates_inclusion_of :length, in: 1..12, message: 'interval must be between 1 and 12 months', if: proc { |s| s.unit == MONTH }

    validates :amount, presence: true, numericality: { greater_than: 0 }

    validates :trial_amount, numericality: { greater_than_or_equal_to: 0, allow_nil: true }, if: proc { |s| s.trial_occurrences.present? }

    validates :trial_occurrences, numericality: { greater_than: 0, only_integer: true, allow_nil: true }

    validates :total_occurrences, numericality: { greater_than: 0, only_integer: true }

    validates_inclusion_of :unit, in: [DAY, MONTH]

    # Subscription record is created before `subscribe` is called, so only validate for this presence when it's updated
    # since it won't initially have a subscription id
    validates_presence_of :subscription_id, on: :update

    after_create :process_later

    def details
      @details ||= Accounting.api(:arb, api_options(profile.accountable)).get_subscription_details(subscription_id)
      if @details && @details.success?
        @details.subscription
      else
        nil
      end
    end

    def cancel
      begin
        cancel!
      rescue Accounting::SubscriptionCanceledError => e
        true
      rescue StandardError => e
        self.errors.add(:base, e.message)
        false
      end
    end

    def cancel!
      profile.accountable.try(:run_hook, :before_subscription_cancel, self)

      if canceled?
        Accounting.log('Subscription', 'Cancel', warn: "Subscription with id #{subscription_id} has already been canceled")
        raise Accounting::SubscriptionCanceledError, "Subscription with id #{subscription_id} has already been canceled"
      end

      response = Accounting.api(:arb, api_options(profile.accountable)).cancel(subscription_id)
      if response.present? && response.success?
        result = update(status: CANCELED)
        profile.accountable.try(:run_hook, :after_subscription_cancel, self) if result
        result
      elsif response.present?
        raise Accounting::SubscriptionError, HTMLEntities.new.decode([response.message_code, response.message_text].join(' '))
      end
    end

    def complete?
      total_occurrences == past_occurrences
    end

    def past_occurrences
      transactions.count
    end

    def process_now
      begin
        process_now!
      rescue Accounting::DuplicateError => e
        Accounting.log('Subscription', 'Process', e.message)
        update(status: :duplicate, submitted_at: Time.now)
        self
      rescue => e
        self.errors.add(:base, e.message)
        false
      end
    end

    def process_now!
      profile.accountable.try(:run_hook, :before_subscription_submit, self)

      begin
        subscribe
      rescue Accounting::DuplicateError => e
        Accounting.log('Subscription', 'Process', e.message)
        update(status: :duplicate, submitted_at: Time.now)
        raise e
      end

      # Flag a job id so that process_later does not unintentionally create a job, but only if it's not already set
      # This method is what is called within the Job
      update_column(:job_id, '0') unless job_id.present?

      profile.accountable.try(:run_hook, :after_subscription_submit, self)

      self
    end

    def process_later
      unless job_id.present?
        job = Accounting::SubscriptionJob.set(queue: queue).perform_later(self)
        update_column(:job_id, job.provider_job_id)
      end
      self
    end

    def processed?
      submitted_at.present? && subscription_id.present?
    end

    def next_transaction_date
      # Reached the end of the subscription, no more transaction dates
      return nil if complete?

      # Current Date/Time
      origin = transactions.order(created_at: :desc).first.try(:created_at) || start_date
      next_transaction = origin

      case unit
        when MONTH
          # Moves the month forward by one, but only to the first of the next month
          length.times { next_transaction = next_transaction.end_of_month + 1.day }

          if origin.day <= Time.days_in_month(next_transaction.month, next_transaction.year)
            # Set the day of the month to the same as the current day
            next_transaction.change(day: origin.day)
          else
            # Or if the month we're in does not have as many days as the month the transaction was originally scheduled in
            # i.e. - Transaction started on Jan 30, but Feb doesn't have 30 days, default to the end of Feb
            next_transaction.end_of_month
          end
        when DAY
          next_transaction + length.days
        else
          nil
      end
    end

    private

      def subscribe
        raise Accounting::DuplicateError, 'Subscription has already been submitted' if processed?

        fields = attributes.symbolize_keys.slice(:name, :description, :unit, :start_date, :total_occurrences, :trial_occurrences, :amount, :trial_amount, :invoice_number, :length)
        fields.merge!(customer_profile_id: profile.profile_id, payment_profile_id: payment.payment_profile_id)

        subscription = AuthorizeNet::ARB::Subscription.new(fields)

        response = Accounting.api(:arb, api_options(profile.accountable)).create(subscription)

        if response.present? && response.success?
          # Keep assign_attributes for these 2 attributes separate since next_transaction_date depends on subscription_id being set
          assign_attributes(subscription_id: response.subscription_id)
          assign_attributes(next_transaction_at: next_transaction_date)
          save
        elsif response.present?
          # Handle duplicate transactions separately
          raise Accounting::DuplicateError, 'Subscription has already been submitted' if response.message_code == 'E00012'

          # Got a response, but it wasn't good
          raise StandardError, HTMLEntities.new.decode([response.message_code, response.message_text].join(' '))
        end
      end

      def cancel_subscription
        begin
          cancel!
        rescue Accounting::SubscriptionCanceledError => e
          true
        rescue StandardError => e
          Accounting.log('Subscription', 'Cancel', error: e.message)
          throw :abort
        end
      end

      def queue
        option(:queue, profile.accountable) || :default
      end

  end
end
