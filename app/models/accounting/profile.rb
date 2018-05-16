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

    validates_length_of :authnet_id, maximum: 20, allow_nil: true, allow_blank: true

    validate :create_profile

    validates_presence_of :profile_id

    before_destroy :delete_profile

    def details(pid=profile_id)
      return nil if pid.nil?
      @details ||= Accounting.api(:cim, api_options(accountable)).get_profile(pid)
      if @details && @details.success?
        @details.profile
      else
        nil
      end
    end

    def transaction_details
      return [] if self.profile_id.blank?
      request = configure_transactions_request
      @response ||= Accounting.api(:api, api_options(accountable)).get_transaction_list_for_customer(request)
      if @response.messages.resultCode == AuthorizeNet::API::MessageTypeEnum::Ok
        return [] if @response.transactions&.transaction.blank?
        @response.transactions.transaction
      else
        # TODO: log error message.
        []
      end
    end

    private

      def create_profile
        return if errors.present? || @details.present?

        customer_profile = AuthorizeNet::CIM::CustomerProfile.new(profile_options)
        response = Accounting.api(:cim, api_options(accountable)).create_profile(customer_profile)
        if response.raw.is_a?(Net::HTTPSuccess)
          if response.message_code == 'E00039' # Profile exists
            profile_id = response.message_text.match(/[0-9]+/).to_s
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
          end

          # Separate if/else in case the catch for error E00039 did not match
          # the configured accountable data
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
        Accounting.api(:cim, api_options(accountable)).delete_profile(profile_id)
      end

      def profile_options
        { email: authnet_email, id: authnet_id, description: authnet_description }.reject { |_,v| v.blank? }
      end

      def configure_transactions_request
        request = AuthorizeNet::API::GetTransactionListForCustomerRequest.new
        request.customerProfileId = self.profile_id

        request.paging = AuthorizeNet::API::Paging.new;
        request.paging.limit = 100;
        request.paging.offset = 1;

        request.sorting = AuthorizeNet::API::TransactionListSorting.new;
        request.sorting.orderBy = AuthorizeNet::API::TransactionListOrderFieldEnum::SubmitTimeUTC
        request.sorting.orderDescending = true;

        request
      end

  end
end
