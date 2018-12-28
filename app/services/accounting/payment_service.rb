module Accounting
  class PaymentService < AccountingService

    def sync!
      if delete?
        resource.destroy!
        return
      end

      # Ensure the transaction has the associated profile and payment associated
      resource.profile_id ||= profile.id

      resource.title ||= title
      resource.address ||= address

      # Assign the attributes
      resource.assign_attributes(
        profile_type: type,
        last_four: last_four,
        expiration: expiration,
        year: -1, # -1 tells the payment model not to validate the expiration date.
        month: -1
      )

      # Assign payment specific attributes (all are pseudo attributes, but needed for validation purposes)
      # In the case of card we set dummy data to ensure rails specific validations pass, the data itself is never saved
      if ach?
        resource.assign_attributes(routing: '0000000', account: '0000000', account_holder: 'Dummy', bank_name: 'Dummy', account_type: 'checking')
      end

      resource.save!
    end

    def resource
      @resource ||= Accounting::Payment.find_or_initialize_by(payment_profile_id: payload[:id])
    end

    def type
      if details.payment.bankAccount.present?
        :ach
      elsif details.payment.creditCard.present?
        :card
      else
        raise Accounting::SyncError.new("Payment profile payment type is blank", payload)
      end
    end

    def card?
      type == :card
    end

    def ach?
      type == :ach
    end

    def title
      case type
        when :ach
          details.payment.bankAccount.bankName
        when :card
          details.payment.creditCard.cardType
      end
    end

    def address
      return unless details.billTo.present?

      Accounting::Address.new(
        first_name: details.billTo.firstName,
        last_name: details.billTo.lastName,
        street_address: details.billTo.streetAddress,
        city: details.billTo.city,
        state: details.billTo.state,
        zip: details.billTo.zip
      )
    end

    def last_four
      case type
        when :ach
          details.payment.bankAccount.accountNumber[-4..-1]
        when :card
          details.payment.creditCard.cardNumber[-4..-1]
      end
    end

    def expiration
      case type
        when :ach
          nil
        when :card
          parse_expiration details.payment.creditCard.expirationDate
      end
    end

    def profile
      if Accounting::Profile.exists?(profile_id: payload[:customer_profile_id])
        Accounting::Profile.find_by(profile_id: payload[:customer_profile_id])
      else
        raise Accounting::SyncWarning.new("Payment profile cannot be created, profile with profile id '#{payload[:customer_profile_id]}' could not be found.", payload)
      end
    end

    def details
      if resource.details.nil?
        raise Accounting::SyncError.new("Payment profile cannot be created because the record could not be found.", payload)
      else
        resource.details
      end
    end

    private

      def parse_expiration(date_str)
        year = date_str.split('-')[0]
        month = date_str.split('-')[1]
        Date.new(year.to_i, month.to_i, -1)
      end

  end
end
