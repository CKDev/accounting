module Accounting
  class AcceptService
    include AuthorizeNet::API
    include AccountingHelper

    attr_accessor :params
    attr_accessor :profile, :payment

    delegate :accountable, to: :profile

    def initialize(params, profile)
      @params = params
      @profile = profile
    end

    ##
    # 1. Validate Payment Address before Authorize.net request
    # 2. Create Authorize.net request to create payment profile
    #
    # @author Ming <ming@commercekitchen.com>
    def build_payment
      @payment = @profile.payments.build(profile_type: @params[:profile_type])
      if @payment.card?
        @payment.assign_attributes(@params[:card])
        return false if @payment.address && @payment.address.invalid?
      end

      create_customer_payment_profile
    end

    def save
      build_payment
      @payment.errors.blank? && @payment.save
    end

    def errors
      @payment.errors
    end

    private

      ##
      # Create Authorize.net createCustomerPaymentProfile Xml request
      # and get newly created payment profile
      # 
      # @author Ming <ming@commercekitchen.com>
      #
      # @reference https://github.com/AuthorizeNet/sample-code-ruby/blob/master/CustomerProfiles/create-customer-payment-profile.rb
      def create_customer_payment_profile
        response = authnet(:api).create_customer_payment_profile(build_request)

        if valid_authnet_response?(response)
          if response.messages.resultCode == MessageTypeEnum::Ok
            Accounting.log 'Payment', 'Accept', info: "Successfully created a customer payment profile with id: #{response.customerPaymentProfileId}."
            @payment.assign_attributes(
              title: response.validationDirectResponse.split(',')[51],
              payment_profile_id: response.customerPaymentProfileId,
              default: @profile.payments.count == 0,
              last_four: response.validationDirectResponse.split(',')[50].to_s[-4..-1]
            )
          else
            error_msg = [response.messages.messages[0].code, response.messages.messages[0].text].join(' ')
            Accounting.log 'Payment', 'Accept', warn: "Failed to create a new customer payment profile - #{error_msg}"
            @payment.errors.add(:base, error_msg)
          end
        else
          Accounting.log 'Payment', 'Accept', warn: 'Response is null'
          @payment.errors.add(:base, 'Failed to create a new customer payment profile.')
        end
      end

      def build_request
        # Build the payment object
        payment_type = PaymentType.new
        payment_type.opaqueData = OpaqueDataType.new('COMMON.ACCEPT.INAPP.PAYMENT', @params[:opaqueData][:dataValue])
        
        # Use the previously defined payment object to
        # build a payment profile to send with the request
        payment_profile = CustomerPaymentProfileType.new
        payment_profile.payment = payment_type

        # Build the request object
        request = CreateCustomerPaymentProfileRequest.new
        request.paymentProfile = payment_profile
        request.customerProfileId = @profile.profile_id
        request.validationMode = api_validation_mode(@profile.accountable)

        request
      end
  end
end
