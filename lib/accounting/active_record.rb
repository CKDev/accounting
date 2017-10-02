module Accounting
  module ActiveRecord

    extend ActiveSupport::Concern

    ACCOUNTABLE_OPTIONS = { email: :email, id: nil, description: nil, queue: nil, api_login: nil, api_key: nil }

    included do
      # Hold
      def hold(amount, payment, **options)
        hold_transaction(amount, payment, options)
      end

      def hold!(amount, payment, **options)
        hold(amount, payment, options).save!
      end

      # Capture
      def capture(transaction, amount=nil, **options)
        capture_transaction(transaction, amount, options)
      end

      def capture!(transaction, amount=nil, **options)
        capture(transaction, amount, options).save!
      end

      # Void
      def void(transaction, **options)
        void_transaction(transaction, options)
      end

      def void!(transaction, **options)
        void(transaction, options).save!
      end

      # Charge
      def charge(amount, payment, **options)
        charge_transaction(amount, payment, options)
      end

      def charge!(amount, payment, **options)
        charge(amount, payment, options).save!
      end

      # Refund
      def refund(amount, transaction, payment=nil, **options)
        refund_transaction(amount, transaction, payment, options)
      end

      def refund!(amount, transaction, payment=nil, **options)
        refund(amount, transaction, payment, options).save!
      end

      # Subscribe
      def subscribe(name, amount, interval, payment, **options)
        subscribe_transaction(name, amount, interval, payment, options)
      end

      def subscribe!(name, amount, interval, payment, **options)
        subscribe(name, amount, interval, payment, options).save!
      end

      private

        def hold_transaction(amount, payment, options)
          options.slice!(:address_id, :split_tender_id, :custom_fields)
          options[:address_id] = options[:address_id].address_id if options[:address_id].present? && options[:address_id].is_a?(Accounting::Address)
          self.transactions.build(transaction_type: :auth_only, amount: amount, payment: payment, options: options)
        end

        def capture_transaction(transaction, amount, options)
          options.slice!(:custom_fields)
          amount ||= transaction.amount
          self.transactions.build(transaction_type: :prior_auth_capture, original_transaction: transaction, amount: amount, options: options)
        end

        def void_transaction(transaction, options)
          options.slice!(:custom_fields)
          self.transactions.build(transaction_type: :void, original_transaction: transaction, options: options)
        end

        def charge_transaction(amount, payment, options)
          options.slice!(:address_id, :split_tender_id, :custom_fields)
          options[:address_id] = options[:address_id].address_id if options[:address_id].present? && options[:address_id].is_a?(Accounting::Address)
          self.transactions.build(transaction_type: :auth_capture, amount: amount, payment: payment, options: options)
        end

        def refund_transaction(amount, transaction, payment, options)
          options.slice!(:custom_fields)
          payment = transaction.payment if payment.nil?
          amount ||= transaction.try(:amount).to_d
          self.transactions.build(transaction_type: :refund, original_transaction: transaction, amount: amount, payment: payment, options: options)
        end

        def subscribe_transaction(name, amount, interval, payment, options)
          options.slice!(:start_date, :total_occurrences, :trial_occurrences, :trial_amount, :invoice_number, :unit, :description)
          options.merge!(name: name, amount: amount, length: interval, payment: payment)
          options[:start_date] ||= Time.now
          options[:unit] ||= AuthorizeNet::ARB::Subscription::IntervalUnits::MONTH
          options[:total_occurrences] ||= AuthorizeNet::ARB::Subscription::UNLIMITED_OCCURRENCES
          self.subscriptions.build(options)
        end

    end

    class_methods do
      
      def accountable(**options)

        include Hooks

        accountable_options = ACCOUNTABLE_OPTIONS.merge(options.symbolize_keys).symbolize_keys

        has_one :profile, as: :accountable, dependent: :destroy, required: true, class_name: '::Accounting::Profile'

        delegate :payments, to: :profile

        delegate :transactions, to: :profile

        delegate :subscriptions, to: :profile

        define_hooks :before_subscription_tick, :after_subscription_tick, :before_transaction_submit, :after_transaction_submit, :before_transaction_sync, :after_transaction_sync, :before_subscription_submit, :after_subscription_submit, :before_subscription_sync, :after_subscription_sync, :before_subscription_cancel, :after_subscription_cancel

        # Expose the options so they can be retrieved later
        after_initialize do
          @_accountable_options = accountable_options
        end

        before_validation do
          options = accountable_options.slice(:email, :id, :description).map do |k,v|
            if v.is_a?(String)
              { "authnet_#{k}" => v }
            elsif v.is_a?(Symbol)
              { "authnet_#{k}" => self.send(v) }
            elsif v.respond_to?(:call)
              { "authnet_#{k}" => v.call(self) }
            end
          end.compact.reduce(:merge)

          self.build_profile(options) unless profile.present?
        end
      end

    end

  end
end
