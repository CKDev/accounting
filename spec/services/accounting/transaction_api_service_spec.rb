require 'spec_helper'

RSpec.describe Accounting::TransactionApiService do

  let(:customer_address) do
    AuthorizeNet::API::CustomerAddressType.new(
      FFaker::Name.first_name,
      FFaker::Name.last_name,
      nil,
      FFaker::Address.street_address,
      FFaker::Address.city,
      FFaker::AddressUS.state_abbr,
      FFaker::AddressUS.zip_code,
      'USA'
    )
  end

  let(:transaction_response) do
    VCR.use_cassette 'valid_charge_no_profile', record: :new_episodes, re_record_interval: 7.days do
      card_number = '4111111111111111'
      expiration_date = '01' + (Time.now + (3600 * 24 * 365)).strftime('%y')
      transaction_request = AuthorizeNet::API::CreateTransactionRequest.new
      transaction_request.transactionRequest = AuthorizeNet::API::TransactionRequestType.new
      transaction_request.transactionRequest.amount = (rand(10000) + 100) / 100.0
      transaction_request.transactionRequest.payment = AuthorizeNet::API::PaymentType.new
      transaction_request.transactionRequest.payment.creditCard = AuthorizeNet::API::CreditCardType.new(card_number, expiration_date, '123') 
      transaction_request.transactionRequest.transactionType = AuthorizeNet::API::TransactionTypeEnum::AuthCaptureTransaction

      transaction = AuthorizeNet::API::Transaction.new(Accounting.config.login, Accounting.config.key, gateway: Accounting.config.gateway)

      transaction.create_transaction(transaction_request).transactionResponse
    end
  end

  let(:email) { FFaker::Internet.email }
  let(:description) { "#{FFaker::Name.first_name} #{FFaker::Name.last_name}" }

  let(:params) do
    {
      transaction_id: transaction_response.transId,
      customer: {
        merchant_customer_id: 99,
        email: email,
        description: description 
      }
    }
  end

  describe '#create_payment_and_profile_from_transaction' do
    let(:api_service) { described_class.new }

    it 'should create a new transaction record' do
      expect do
        api_service.create_payment_from_profile_and_transaction(request_params: params, accountable: nil)
      end.to change(Accounting::Transaction, :count).by(1)
    end

    it 'should create a new payment' do
      expect do
        api_service.create_payment_from_profile_and_transaction(request_params: params, accountable: nil)
      end.to change(Accounting::Payment, :count).by(1)
    end

    it 'should create a new profile' do
      expect do
        api_service.create_payment_from_profile_and_transaction(request_params: params, accountable: nil)
      end.to change(Accounting::Profile, :count).by(1)
    end

    describe 'return values' do
      let(:service_response) { api_service.create_payment_from_profile_and_transaction(request_params: params, accountable: nil) }

      it 'should return a profile' do
        expect(service_response[:profile]).to be_a(Accounting::Profile)
       end

      it 'should return a payment profile' do
        expect(service_response[:payment_profile]).to be_a(Accounting::Payment)
      end
    end

    describe 'created data' do
      before do
        api_service.create_payment_from_profile_and_transaction(request_params: params, accountable: nil)
        @profile = Accounting::Profile.last
        @payment_profile = Accounting::Payment.last
        @transaction = Accounting::Transaction.last
      end

      it 'should create a new profile with correct email' do
        expect(@profile.authnet_email).to eq(email)
      end

      it 'should create a new profile with correct description' do
        expect(@profile.authnet_description).to eq(description)
      end

      it 'should connect the new payment and profile' do
        expect(@payment_profile.profile).to eq(@profile)
      end

      it 'should connect new transaction with profile' do
        expect(@transaction.profile).to eq(@profile)
      end

      it 'should connect new transaction with payment profile' do
        expect(@transaction.payment).to eq(@payment_profile)
      end
    end
  end

end