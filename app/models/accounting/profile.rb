module Accounting
  class Profile < ::ActiveRecord::Base

    include AccountingHelper

    belongs_to :accountable, polymorphic: true, required: true

    has_many :payments, inverse_of: :profile, autosave: true, dependent: :destroy do
      def default
        find_by(default: true) || first
      end
    end

    has_many :transactions, inverse_of: :profile, autosave: true, dependent: :destroy

    has_many :subscriptions, inverse_of: :profile, autosave: true, dependent: :destroy

    validates_length_of :authnet_id, maximum: 20, allow_nil: true, allow_blank: true

    validate :create_profile

    validates_presence_of :profile_id, message: 'Missing authnet profile_id'

    before_destroy :delete_profile

    after_update :update_profile

    def details(pid=profile_id)
      return nil if pid.nil?

      request = GetCustomerProfileRequest.new
      request.customerProfileId = pid

      @response ||= authnet(:api).get_customer_profile(request)
      if valid_authnet_response?(@response) && @response.messages.resultCode == MessageTypeEnum::Ok
        @response.profile
      else
        nil
      end
    end

    private

      def create_profile
        return if errors.present? || details.present?

        response = authnet(:api).create_customer_profile(create_request)
        if valid_authnet_response?(response)
          if response.messages.resultCode == MessageTypeEnum::Ok && response.customerProfileId.present?
            assign_attributes(profile_id: response.customerProfileId)
          elsif response.messages.messages[0].code == 'E00039' # Profile exists
            profile_id = response.messages.messages[0].text.match(/[0-9]+/).to_s
            info = details(profile_id)

            # If profile details were found for the matching profile id,
            # check and see if they match the configured accountable data.
            # If so, it is safe to assume that the found duplicate profile id
            # is in fact the accountable records profile, so we'll update the id
            if info.present?
              actual      = [:id, :email, :description].map { |k| info.send(k) }
              configured  = [:id, :email, :description].map { |k| self["authnet_#{k}"] }

              assign_attributes(profile_id: profile_id) if actual == configured
              return
            end
          else
            # Did not get a 200 OK response, add the error message whatever it might be
            self.errors.add(:base, [response.messages.messages[0].code, response.messages.messages[0].text].join(' '))
          end
        else
          self.errors.add(:base, ['Null Response', 'Failed to create a new customer profile.'].join(' '))
        end
      end

      def update_profile
        authnet(:api).update_customer_profile(update_request)
      end

      def delete_profile
        request = DeleteCustomerProfileRequest.new(nil, nil, profile_id)
        authnet(:api).delete_customer_profile(request)
      end

      def create_request
        request = CreateCustomerProfileRequest.new
        # Build the profile object containing the main information about the customer profile
        request.profile = CustomerProfileType.new
        request.profile.merchantCustomerId = authnet_id
        request.profile.description = authnet_description
        request.profile.email = authnet_email
        request.validationMode = ValidationModeEnum::None
        request
      end

      def update_request
        request = UpdateCustomerProfileRequest.new
        request.profile = CustomerProfileExType.new

        # Edit this part to select a specific customer
        request.profile.customerProfileId = profile_id
        request.profile.merchantCustomerId = authnet_id
        request.profile.description = authnet_description
        request.profile.email = authnet_email
        request
      end
  end
end
