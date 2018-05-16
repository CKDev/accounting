require 'spec_helper'

RSpec.describe Accounting::Payment, type: :model do

  let(:payment) { FactoryGirl.build(:accounting_payment, :with_card) }

  it 'should support instantiation' do
    expect(Accounting::Payment.new).to be_instance_of(Accounting::Payment)
  end

  describe 'default payment' do
    it 'should be the default payment if first payment method' do
      VCR.use_cassette :valid_payment, record: :new_episodes, re_record_interval: 7.days do
        expect(payment.profile.payments.count).to eq(0)
        payment.save!
        expect(payment.profile.payments.count).to eq(1)
        expect(payment.reload.default?).to be_truthy
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

  it 'should fail to validate if the expiration date is in the past' do
    payment.month = 1
    payment.year = 2005
    expect(payment).to_not be_valid
    expect(payment.errors.full_messages).to eq(['Expiration date cannot be in the past'])
  end

  context 'Credit Card' do

    it 'should have an appropriate card title' do
      expect(payment.title).not_to be_empty
    end

    it 'should have payment profile id' do
      VCR.use_cassette :valid_payment, record: :new_episodes, re_record_interval: 7.days do
        payment.payment_profile_id = nil
        payment.valid?
        expect(payment.errors.full_messages).to eq(['Payment profile can\'t be blank'])
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

    let(:payment_card) { FactoryGirl.build(:accounting_payment, :with_card) }

    it 'should not run create_payment when create from payment nonce' do
      expect(payment_card).not_to receive(:create_payment)
      payment_card.save
    end
  end

end
