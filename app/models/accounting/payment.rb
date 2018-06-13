module Accounting
  class Payment < ::ActiveRecord::Base

    include AccountingHelper

    belongs_to :profile, inverse_of: :payments, required: true

    has_one :address, inverse_of: :payment, autosave: true, dependent: :destroy

    before_destroy :delete_payment

    after_create :reset_default

    after_destroy :reset_default

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

    def details
      @details ||= Accounting.api(:cim, api_options(profile.accountable)).get_payment_profile(payment_profile_id, profile.profile_id)

      if @details && @details.success?
        @details.payment_profile
      else
        nil
      end
    end

    def default!
      if profile.present? && !profile.destroyed?
        profile.payments.where(default: true).where.not(id: id).update_all(default: false)
        update_attribute(:default, true) unless destroyed?
      end
    end

    private

      def create_payment
        # Don't bother creating the payment if errors exist on self or the address at this point, it will fail to validate anyways
        return if errors.present? || (address.present? && address.errors.present?)

        ach = AuthorizeNet::ECheck.new(routing, account, bank_name, account_holder, { account_type: account_type, check_number: check_number, echeck_type: echeck_type || AuthorizeNet::ECheck::CheckType::INTERNET_INITIATED })
        payment_profile = AuthorizeNet::CIM::PaymentProfile.new(payment_method: ach, billing_address: address&.to_billing_address)

        response = Accounting.api(:cim, api_options(profile.accountable)).create_payment_profile(payment_profile, profile.profile_id, validation_mode: Accounting.config.validation_mode)

        if response.success?
          if response.validation_response.present?
            # Add the payment attributes. Expiration only applies to card payment types
            # If no payment types exist yet, make the first one the default
            assign_attributes(
              title: response.validation_response.fields[:card_type],
              payment_profile_id: response.payment_profile_id,
              default: profile.payments.count == 0,
              last_four: response.validation_response.fields[:account_number].to_s[-4..-1]
            )
          end
        else
          # All is not well, include the authorize.net error code and message
          self.errors.add(:base, [response.message_code, response.message_text].join(' '))
        end
      end

      # Delete the associated payment profile on Authorize.net when this instance is destroyed
      def delete_payment
        Accounting.api(:cim, api_options(profile.accountable)).delete_payment_profile(payment_profile_id, profile.profile_id) unless Rails.env.test?
      end

      def reset_default
        if profile.payments.where(default: true).count.zero?
          profile.payments.first.try(:default!)
        end
      end

      def expiration_date
        # Allow an out for the edge case where Authorize.NET sends the hook to create a payment profile
        # It does not send expiration dates, so we need to allow nil in this case and treat it as "Unknown"
        return if year == -1 && month == -1

        self.errors.add(:base, 'Expiration date cannot be in the past') unless Time.new(year.to_i, month.to_i, Time.now.day, Time.now.hour, Time.now.min, 0) > Time.now
      rescue ArgumentError
        self.errors.add(:base, 'Expiration date is invalid')
      end

      def format_data
        # Ensure the year is 4 digit representation
        self.year = '20' + year.to_s[-2..-1].to_s unless year == -1
        self.expiration = Date.new(year.to_i, month.to_i, -1) rescue nil
      end

  end
end
