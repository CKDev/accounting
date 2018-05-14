require 'spec_helper'

RSpec.describe Accounting::AcceptService do

  let(:payment_params) {
    {
      profile_type: 'card',
      opaqueData: {
        dataDescriptor: 'COMMON.ACCEPT.INAPP.PAYMENT',
        dataValue: ''
      },
      card: {
        month: '11',
        year: '2019',
        address_attributes: {
          first_name: 'John',
          last_name: 'Stanfield',
        },
      }
    }
  }
  let(:profile) { FactoryGirl.create(:accounting_profile) }
  let(:service) { Accounting::AcceptService.new(payment_params, profile) }

  it 'should create a payment profile from opaque data' do

    api_response = double(
      :api_response,
      messages: double(:messages, resultCode: AuthorizeNet::API::MessageTypeEnum::Ok),
      customerPaymentProfileId: '12345'
    )
    expect(service).to receive(:parsed_response).twice.and_return({ card_type: 'Visa', account_number: 'xxxx1234' })
    expect_any_instance_of(AuthorizeNet::API::Transaction).to receive(:create_customer_payment_profile).and_return(api_response)
    VCR.use_cassette :valid_address, record: :new_episodes, re_record_interval: 7.days do
      expect(service.save).to be_truthy
    end
  end
end
