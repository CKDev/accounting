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
        year: '2021',
        address_attributes: {
          first_name: 'John',
          last_name: 'Stanfield',
        },
      }
    }
  }
  let(:profile) { FactoryBot.create(:accounting_profile) }
  let(:service) { Accounting::AcceptService.new(payment_params, profile) }

  it 'should create a payment profile from opaque data' do

    api_response = double(
      :api_response,
      messages: double(:messages, resultCode: AuthorizeNet::API::MessageTypeEnum::Ok),
      customerPaymentProfileId: '12345',
      validationDirectResponse: [',' * 48, 'xxxx1234', 'Visa'].join(',') # account_number and card_type comes at 50, 51 index
    )
    expect_any_instance_of(AuthorizeNet::API::Transaction).to receive(:create_customer_payment_profile).and_return(api_response)
    VCR.use_cassette :valid_address, record: :new_episodes, re_record_interval: 7.days do
      expect(service.save).to be_truthy
    end
  end
end
