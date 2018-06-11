include AuthorizeNet::API
include AccountingHelper

module Accounting
  class TransactionApiService

    def create_payment_from_profile_and_transaction(request_params:, accountable:)
      request = customer_profile_from_transaction_request(request_params)
      response = Accounting.api(:api, api_options(accountable)).create_customer_profile_from_transaction(request)

      profile_id = response.customerProfileId
      payment_profile_id = response.customerPaymentProfileIdList.numericString.first

      profile = Accounting::Profile.new(profile_id: profile_id)
      profile.save(validate: false)

      payment_profile = Accounting::Payment.new(payment_profile_id: payment_profile_id, profile: profile)
      payment_profile.save(validate: false)

      Accounting::ProfileService.new(id: profile_id).sync!
      Accounting::PaymentService.new(id: payment_profile_id).sync!

      # Create Transaction
      transaction = Accounting::Transaction.new(transaction_id: request_params[:transaction_id], profile_id: profile.id, payment_id: payment_profile.id)
      transaction.save(validate: false)

      Accounting::TransactionService.new(id: request_params[:transaction_id]).sync!

      return {
        profile: profile,
        payment_profile: payment_profile
      }
    end

    private

      def customer_profile_from_transaction_request(params)
        CreateCustomerProfileFromTransactionRequest.new.tap do |req|
          req.transId = params[:transaction_id]
          req.customer = new_customer_from_data(params[:customer])
        end
      end

      def new_customer_from_data(params)
        CustomerProfileBaseType.new(
          params[:merchant_customer_id],
          params[:description],
          params[:email]
        )
      end
  end
end
