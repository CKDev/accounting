module Accounting
  class Profile < ::ActiveRecord::Base

    include AccountingHelper

    belongs_to :accountable, polymorphic: true, optional: true, class_name: '::Accounting::Profile'

    has_many :payments, inverse_of: :profile, autosave: true, dependent: :destroy do
      def default
        find_by(default: true) || first
      end
    end

    has_many :transactions, inverse_of: :profile, autosave: true, dependent: :destroy

    has_many :subscriptions, inverse_of: :profile, autosave: true, dependent: :destroy

    validates_uniqueness_of :authnet_email

    validates_length_of :authnet_id, maximum: 20, allow_nil: true, allow_blank: true

    validate :create_profile

    before_destroy :delete_profile, if: proc { |p| p.profile_id.present? }

    def details
      @details ||= Accounting.api(:cim, api_options(accountable)).get_profile(profile_id)
      if @details && @details.success?
        @details.profile
      else
        nil
      end
    end

    private

      def create_profile
        return if errors.present? || profile_id.blank?

        customer_profile = AuthorizeNet::CIM::CustomerProfile.new(profile_options)
        response = Accounting.api(:cim, api_options(accountable)).create_profile(customer_profile)

        if response.raw.is_a?(Net::HTTPSuccess)
          if response.success? && response.profile_id.present?
            assign_attributes(profile_id: response.profile_id)
          else
            self.errors.add(:base, [response.message_code, response.message_text].join(' '))
          end
        else
          # Did not get a 200 OK response, add the error message whatever it might be
          self.errors.add(:base, response.raw.message)
        end
      end

      def delete_profile
        Accounting.api(:cim, api_options(accountable)).delete_profile(profile_id) unless Rails.env.test?
      end

      def profile_options
        { email: authnet_email, id: authnet_id, description: authnet_description }.reject { |_,v| v.blank? }
      end

  end
end