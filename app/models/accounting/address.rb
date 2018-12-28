module Accounting
  class Address < ::ActiveRecord::Base

    include AccountingHelper

    belongs_to :payment, inverse_of: :address, required: true

    validate :create_address, if: proc { |a| a.address_id.blank? }

    before_destroy :delete_address, if: proc { |a| a.address_id.present? && a.profile.present? }

    delegate :profile, to: :payment

    delegate :accountable, to: :profile

    def to_billing_address
      CustomerAddressType.new(*address_fields)
    end

    private

      def create_address
        # If we already have errors, or our associated payment method has errors, don't bother creating the address
        return if errors.present? || payment.errors.present?

        response = authnet(:api).create_customer_shipping_profile(create_request)

        unless response == nil || response.is_a?(Exception)
          if response.messages.resultCode == MessageTypeEnum::Ok
            assign_attributes(address_id: response.customerAddressId)
          elsif response.messages.resultCode == 'E00039'
            # Duplicate address, so just assign the address id associated
            assign_attributes(address_id: response.customerAddressId)
          else
            # All is not well, include the authorize.net error code and message
            self.errors.add(:base, [response.messages.messages[0].code, response.messages.messages[0].text].join(' '))
          end
        else
          self.errors.add(:base, ['Null Response', 'Failed to create a new customer address.'].join(' '))
        end
      end

      # Delete the associated payment profile on Authorize.net when this instance is destroyed
      def delete_address
        request = DeleteCustomerShippingAddressRequest.new(nil, nil, profile.profile_id, address_id)
        authnet(:api).delete_customer_shipping_profile(request) unless Rails.env.test?
      end

      def address_fields
        fields = attributes.symbolize_keys.slice(:first_name, :last_name, :company, :street_address, :city, :state, :zip, :country, :phone, :fax)
        # Remove commas, since it will screw with the comma delimited response string that authorize.net sends back
        fields.map { |k, v| v.to_s.gsub(/,+/, '') }
      end

      def create_request
        request = CreateCustomerShippingAddressRequest.new
        
        request.address = to_billing_address
        request.customerProfileId = profile.profile_id
        request
      end

  end
end
