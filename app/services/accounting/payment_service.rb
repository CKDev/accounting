module Accounting
  class PaymentService < AccountingService

    def sync!
      if delete?
        resource.destroy!
        return
      end

      # Ensure the transaction has the associated profile and payment associated
      resource.profile_id ||= profile.id

      raise Accounting::SyncError.new("Payment profile with id #{payload[:id]} not found in Authorize.NET", payload) if resource.details.nil?

      resource.title ||= title
      resource.address ||= address

      # Assign the attributes
      resource.assign_attributes(
        profile_type: type,
        last_four: last_four,
        year: -1, # -1 tells the payment model not to validate the expiration date.
        month: -1 # We do this because authorize.net does not provide expiration info, so we treat nil expiration as unknown
      )

      # Assign payment specific attributes (all are pseudo attributes, but needed for validation purposes)
      # In the case of card we set dummy data to ensure rails specific validations pass, the data itself is never saved
      if ach?
        resource.assign_attributes(routing: '0000000', account: '0000000', account_holder: 'Dummy', bank_name: 'Dummy', account_type: 'checking')
      elsif card?
        resource.assign_attributes(number: '0000000000000000', ccv: '000')
      end

      resource.save!
    end

    def resource
      @resource ||= Accounting::Payment.find_or_initialize_by(payment_profile_id: payload[:id])
    end

    def type
      if resource.details.payment_method.is_a?(AuthorizeNet::ECheck)
        :ach
      elsif resource.details.payment_method.is_a?(AuthorizeNet::CreditCard)
        :card
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
          resource.details.payment_method.bank_name
        when :card
          resource.details.payment_method.card_type
      end
    end

    def address
      Accounting::Address.new(
        first_name: resource.details.billing_address.first_name,
        last_name: resource.details.billing_address.last_name,
        street_address: resource.details.billing_address.street_address,
        city: resource.details.billing_address.city,
        state: resource.details.billing_address.state,
        zip: resource.details.billing_address.zip
      )
    end

    def last_four
      case type
        when :ach
          resource.details.payment_method.account_number[-4..-1]
        when :card
          resource.details.payment_method.card_number[-4..-1]
      end
    end

    def profile
      if Accounting::Profile.exists?(profile_id: payload[:customer_profile_id])
        Accounting::Profile.find_by(profile_id: payload[:customer_profile_id])
      else
        raise Accounting::SyncWarning.new("Payment profile cannot be created, profile with profile id '#{payload[:customer_profile_id]}' could not be found.", payload)
      end
    end

  end
end
