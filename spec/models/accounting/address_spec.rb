require 'spec_helper'

RSpec.describe Accounting::Address, type: :model do

  let(:address) { FactoryGirl.build(:accounting_address, :with_payment) }

  it 'can be fetched as a billing address' do
    expect(address.to_billing_address).to be_instance_of(AuthorizeNet::API::CustomerAddressType)
  end

  it 'can create an address profile' do
    VCR.use_cassette :valid_address, record: :new_episodes, re_record_interval: 7.days do
      expect(address.address_id).to be_nil
      address.save!
      expect(address.address_id).to_not be_nil
    end
  end

  it 'will have address errors if the address could not be created' do
    address = FactoryGirl.build(:accounting_address)

    VCR.use_cassette :invalid_address do
      expect(address).to_not be_valid
    end
  end

end
