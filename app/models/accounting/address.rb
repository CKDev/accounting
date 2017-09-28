module Accounting
  class Address < ::ActiveRecord::Base

    belongs_to :payment, inverse_of: :address, required: true

    validate :create_address, if: proc { |a| a.address_id.blank? }

    before_destroy :delete_address, if: proc { |a| a.address_id.present? && a.profile.present? }

    delegate :profile, to: :payment

    def to_billing_address
      AuthorizeNet::Address.new(address_fields)
    end

    def to_shipping_address
      AuthorizeNet::ShippingAddress.new(address_fields)
    end

    private

      def create_address
        # If we already have errors, or our associated payment method has errors, don't bother creating the address
        return if errors.present? || payment.errors.present?

        response = Accounting.api(:cim).create_address(to_billing_address, profile.profile_id)

        if response.success?
          assign_attributes(address_id: response.address_id)
        elsif response.message_code == 'E00039'
          # Duplicate address, so just assign the address id associated
          assign_attributes(address_id: response.address_id)
        else
          # All is not well, include the authorize.net error code and message
          self.errors.add(:base, [response.message_code, response.message_text].join(' '))
        end
      end

      # Delete the associated payment profile on Authorize.net when this instance is destroyed
      def delete_address
        Accounting.api(:cim).delete_address(address_id, profile.profile_id) unless Rails.env.test?
      end

      def address_fields
        fields = attributes.symbolize_keys.slice(:first_name, :last_name, :company, :street_address, :city, :state, :zip, :country, :phone, :fax)
        # Remove commas, since it will screw with the comma delimited response string that authorize.net sends back
        fields.map { |k,v| { k => v.to_s.gsub(/,+/, '') } }.compact.reduce(Hash.new, :merge)
      end

  end
end
