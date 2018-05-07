require 'spec_helper'

RSpec.describe Accounting::Payment, type: :model do

  let(:payment) { FactoryGirl.build(:accounting_payment, :with_card) }

  it 'should support instantiation' do
    expect(Accounting::Payment.new).to be_instance_of(Accounting::Payment)
  end

  it 'should initially not have a payment profile id' do
    expect(payment.payment_profile_id).to be_nil
  end

  it 'should have a payment profile id after creation' do
    VCR.use_cassette :valid_payment, record: :new_episodes, re_record_interval: 7.days do
      payment.save
      expect(payment.payment_profile_id).to_not be_nil
    end
  end

  describe 'default payment' do
    it 'should be the default payment if first payment method' do
      VCR.use_cassette :valid_payment, record: :new_episodes, re_record_interval: 7.days do
        expect(payment.profile.payments.count).to eq(0)
        payment.save!
        expect(payment.profile.payments.count).to eq(1)
        expect(payment.default?).to be_truthy
      end
    end

    it 'should make default payment when default! called' do
      VCR.use_cassette :valid_payment, record: :new_episodes, re_record_interval: 7.days do
        payment.save!
        expect(payment.default?).to be_truthy
        payment2 = FactoryGirl.create(:accounting_payment, :with_card, profile: payment.profile)
        payment2.default!
        expect(payment.reload.default?).to be_falsey
        expect(payment2.reload.default?).to be_truthy
      end
    end
  end

  it 'should have an appropriate length card number' do
    payment.number = '111'
    expect(payment).to_not be_valid
    expect(payment.errors.full_messages).to eq(['Number is too short (minimum is 13 characters)'])
  end

  it 'should fail to validate if the expiration date is in the past' do
    payment.month = 1
    payment.year = 2005
    expect(payment).to_not be_valid
    expect(payment.errors.full_messages).to eq(['Expiration date cannot be in the past'])
  end

  it 'should fail to validate with errors from authorize.net' do
    VCR.use_cassette :invalid_payment, record: :new_episodes, re_record_interval: 7.days do
      payment.ccv = 1234567890
      expect(payment).to_not be_valid
      expect(payment.errors.full_messages).to eq(["E00003 The 'AnetApi/xml/v1/schema/AnetApiSchema.xsd:cardCode' element is invalid - The value XXXXXXXXXXXX is invalid according to its datatype 'AnetApi/xml/v1/schema/AnetApiSchema.xsd:cardCode' - The actual length is greater than the MaxLength value."])
    end
  end

  context 'Credit Card' do

    let(:profile) { FactoryGirl.create(:accounting_profile, :with_all_cards) }

    it 'should have an appropriate card title' do
      types = {
        '0002' => 'American Express',
        '0012' => 'Discover',
        '0017' => 'JCB',
        '0027' => 'Visa',
        '0015' => 'MasterCard'
      }

      profile.payments.each do |payment|
        expect(payment.title).to eq(types[payment.last_four])
      end
    end

  end

  context 'ACH' do

    it 'should have an appropriate ach title' do
      types = ['checking', 'savings']

      types.each do |type|
        VCR.use_cassette "payment_ach_#{type}", record: :new_episodes, re_record_interval: 7.days do
          payment = FactoryGirl.create(:accounting_payment, :with_ach, account_type: type)
          expect(payment.title).to eq('Bank Account')
        end
      end
    end

  end

  context 'Opaque Data(Accept.js)' do

    let(:payment_card) { FactoryGirl.build(:accounting_payment, :with_card_opaque_data) }
    let(:payment_ach) { FactoryGirl.build(:accounting_payment, :with_ach_opaque_data) }

    it 'should skip customer payment details validation' do
      expect(payment_card.errors.messages.keys).not_to include(:number, :ccv)
      expect(payment_ach.errors.messages.keys).not_to include(:routing, :account, :bank_name, :account_holder, :account_type)
    end

  end

end
