module Accounting
  module Test
    ##
    # Since we will use Accept.js for payment creation, we need a way to create Payment Profile in original way(with card data)
    # for tests. <tt>Accounting::Test::CreateCard<tt> provides the way.
    class CreateCard

      include AccountingHelper

      attr_accessor :address, :profile, :payment
      attr_accessor :number, :ccv, :month, :year

      delegate :accountable, to: :profile

      def initialize(profile, number, ccv, month, year, address)
        @profile = profile
        @ccv = ccv
        @month = month || rand(1..12).to_i
        @year = year || Time.now.year.to_i + 5
        # Ensure the credit card number is only numbers (no spaces, dashes, etc)
        @number = number.to_s.gsub(/[^0-9]+/, '')
        @address = address

        @payment = @profile.payments.build(profile_type: 'card', address: @address, month: @month, year: @year)
      end

      def create_payment
        response = authnet(:api).create_customer_payment_profile(request)
        if valid_authnet_response?(response)
          if response.messages.resultCode == MessageTypeEnum::Ok
            payment.assign_attributes(
              title:  response.validationDirectResponse.split(',')[51],
              payment_profile_id: response.customerPaymentProfileId,
              default: profile.payments.count == 0,
              last_four:  response.validationDirectResponse.split(',')[50].to_s[-4..-1]
            )
          else
            payment.errors.add(:base, [response.messages.messages[0].code, response.messages.messages[0].text].join(' '))
          end
        else
          payment.errors.add(:base, 'Null Response')
        end
        payment
      end

      def request
        # Build the payment object
        payment = PaymentType.new(CreditCardType.new)
        payment.creditCard.cardNumber = number
        payment.creditCard.expirationDate = expiration_str
        payment.creditCard.cardCode = ccv
        # Use the previously defined payment and billTo objects to
        # build a payment profile to send with the request
        paymentProfile = CustomerPaymentProfileType.new
        paymentProfile.payment = payment
        paymentProfile.billTo = address&.to_billing_address
        paymentProfile.defaultPaymentProfile = true

        # Build the request object
        request = CreateCustomerPaymentProfileRequest.new
        request.paymentProfile = paymentProfile
        request.customerProfileId = profile.profile_id
        request.validationMode = ValidationModeEnum::LiveMode
        request
      end

      def expiration_str
        "#{year}-#{month.to_s.rjust(2, '0')}"
      end
    end
  end
end