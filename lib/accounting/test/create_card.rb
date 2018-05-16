module Accounting
  module Test
    ##
    # Since we will use Accept.js for payment creation, we need a way to create Payment Profile in original way(with card data)
    # for tests. <tt>Accounting::Test::CreateCard<tt> provides the way.
    class CreateCard
      attr_accessor :address, :profile, :payment
      attr_accessor :number, :ccv, :month, :year

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
        payment_profile = AuthorizeNet::CIM::PaymentProfile.new(payment_method: card, billing_address: address&.to_billing_address)
        response = Accounting.api(:cim).create_payment_profile(payment_profile, profile.profile_id, validation_mode: Accounting.config.validation_mode)
        if response.success?
          if response.validation_response.present?
            # Add the payment attributes. Expiration only applies to card payment types
            # If no payment types exist yet, make the first one the default
            @payment.assign_attributes(
              title: response.validation_response.fields[:card_type],
              payment_profile_id: response.payment_profile_id,
              default: profile.payments.count == 0,
              last_four: response.validation_response.fields[:account_number].to_s[-4..-1]
            )
          end
        else
          # All is not well, include the authorize.net error code and message
          @payment.errors.add(:base, [response.message_code, response.message_text].join(' '))
        end

        @payment
      end

      def card
        AuthorizeNet::CreditCard.new(number, expiration_str, card_code: ccv)
      end

      def expiration_str
        "#{month.to_s.rjust(2, '0')}#{year.to_s[-2..-1]}"
      end
    end
  end
end