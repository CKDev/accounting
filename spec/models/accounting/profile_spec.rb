require 'spec_helper'

RSpec.describe Accounting::Profile, type: :model do

  let(:profile) { FactoryGirl.build(:accounting_profile) }

  it 'should support instantiation' do
    expect(Accounting::Profile.new).to be_instance_of(Accounting::Profile)
  end

  it 'should initially not have a profile id' do
    expect(profile.profile_id).to be_nil
  end

  it 'should have a profile id after creation' do
    VCR.use_cassette :valid_profile, record: :new_episodes, re_record_interval: 7.days do
      profile.save!
      expect(profile.profile_id).to_not be_nil
    end
  end

  xit 'should have a unique email address' do
    VCR.use_cassette :valid_profile, record: :new_episodes, re_record_interval: 7.days do
      expect(profile).to be_valid
      profile.save!
    end
    email = profile.authnet_email

    new_profile = FactoryGirl.build(:accounting_profile, authnet_email: email)
    expect(new_profile).to_not be_valid
    expect(new_profile.errors.full_messages).to eq(['Authnet email has already been taken'])
  end

  it 'should fail to validate if an authorize.net error was returned' do
    profile.authnet_description = 'WORD' * 100
    VCR.use_cassette :invalid_profile, record: :new_episodes, re_record_interval: 7.days do
      expect(profile).to_not be_valid
    end
  end

  it 'should fail to validate with the request errors if not a 200 response' do
    stub_request(:any, 'https://apitest.authorize.net/xml/v1/request.api').to_raise('Blocked')
    expect(profile).to_not be_valid
    expect(profile.errors.full_messages).to eq(['Blocked', 'Profile can\'t be blank'])
  end

  it 'should delete the customer profile when destroyed' do
    VCR.use_cassette :valid_profile, record: :new_episodes, re_record_interval: 7.days do
      profile.save!
    end

    VCR.use_cassette :delete_profile, record: :new_episodes, re_record_interval: 7.days do
      expect(profile.profile_id).to_not be_nil
      expect_any_instance_of(Accounting::Profile).to receive(:delete_profile)
      profile.destroy
    end
  end

  context 'Payments' do

    let(:profile) do
      VCR.use_cassette :valid_profile, record: :new_episodes, re_record_interval: 7.days do
        FactoryGirl.create(:accounting_profile, :with_payment, payment_count: 3)
      end
    end

    it 'should always have a default payment if there is one or more payment methods' do
      expect(profile.payments.count).to eq(3)
      expect(profile.payments.default).to be_a(Accounting::Payment)
      profile.payments.default.destroy!
      expect(profile.payments.count).to eq(2)
      expect(profile.payments.default).to be_a(Accounting::Payment)
    end

  end

end
