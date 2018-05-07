module Accounting
  class AcceptService
    include AuthorizeNet::API
    include AccountingHelper

    attr_accessor :params
    attr_accessor :profile, :payment

    def initialize(params, profile)
      @params = params
      @profile = profile
    end

    ##
    # 1. Validate Payment Address before Authorize.net request
    # 2. Create Authorize.net request to create payment profile
    #
    # @author Ming <ming@commercekitchen.com>
    #
    # @return {Bool} True if payment and address created successfully
    def create_payment
      @payment = @profile.payments.build(accept: true, profile_type: @params[:profile_type])
      if @payment.card?
        @payment.assign_attributes(@params[:card])
        if @payment.address && @payment.address.invalid?
          # Don't want to run payment validation when addres is invalid
          @errors = @payment.address.errors
          return false
        end  
      end

      create_customer_payment_profile
    end

    def errors
      @errors || @payment.errors
    end

    private

      ##
      # Create Authorize.net createCustomerPaymentProfile Xml request
      # and get newly created payment profile
      # 
      # @author Ming <ming@commercekitchen.com>
      #
      # @reference https://github.com/AuthorizeNet/sample-code-ruby/blob/master/CustomerProfiles/create-customer-payment-profile.rb
      #
      # @return {Bool} True or False on whether payment profile has been created
      def create_customer_payment_profile
        transaction = Accounting.api(:api, api_options(@profile.accountable))
        @response = transaction.create_customer_payment_profile(build_request)

        if @response != nil
          if @response.messages.resultCode == MessageTypeEnum::Ok
            Accounting.log 'Payment', 'Accept', info: "Successfully created a customer payment profile with id: #{@response.customerPaymentProfileId}."
            @payment.assign_attributes(
              title: parsed_response[:card_type],
              payment_profile_id: @response.customerPaymentProfileId,
              default: @profile.payments.count == 0,
              last_four: parsed_response[:account_number].to_s[-4..-1]
            )
            return @payment.save
          else
            error_msg = "#{@response.messages.messages[0].code} #{@response.messages.messages[0].text}"
            Accounting.log 'Payment', 'Accept', warn: "Failed to create a new customer payment profile - #{error_msg}"
            @errors = [error_msg]
          end
        else
          Accounting.log 'Payment', 'Accept', warn: 'Response is null'
          @errors = ["Failed to create a new customer payment profile."]
        end

        false
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
        request.validationMode = Accounting.config.validation_mode

        request
      end

      def parsed_response
        @parsed_response ||= AuthorizeNet::AIM::Response.new(@response.to_xml, Accounting.api(:cim, api_options(@profile.accountable))).fields
      end
  end
end
