require 'spec_helper'

RSpec.describe Accounting::Transaction, type: :model do

  before(:all) { ActiveJob::Base.queue_adapter = :test }

  let(:user) { FactoryGirl.create(:user, :with_payment, :with_transactions) }

  before(:each) { user.transactions }

  it 'should support instantiation' do
    expect(Accounting::Transaction.new).to be_instance_of(Accounting::Transaction)
  end

  it 'should return self if already processed' do
    charge = user.charge(1.00, user.payments.default)
    charge.save

    expect { charge.process_now! }.to_not raise_error # First call should be fine
    expect(charge.process_now!).to eq(charge)
  end

  it 'should raise a duplicate transaction error if previously submitted' do
    charge1 = user.charge(1.00, user.payments.default)
    charge2 = user.charge(1.00, user.payments.default)
    charge1.save
    charge2.save

    expect { charge1.process_now! }.to_not raise_error # First call should be fine
    expect { charge2.process_now! }.to raise_error(::Accounting::DuplicateError)
  end

  it 'will fetch the address if an address instance is provided' do
    address = FactoryGirl.create(:accounting_address, :with_payment, :with_address_id)
    charge = user.charge(1.00, user.payments.default, address_id: '0')
    expect(charge).to be_valid
    expect(charge.options['address_id']).to eq('0')
    
    charge = user.charge(1.00, user.payments.default, address_id: address)
    expect(charge).to be_valid
    expect(charge.options['address_id']).to be_present
    expect(charge.options['address_id']).to eq(address.address_id)
  end

  xit 'will have errors from authorize.net requests that fail, but are not duplicates', focus: true do
    charge = user.charge(1.00, user.payments.default)
    VCR.use_cassette(:invalid_charge) { charge.process_now }
    expect(charge.errors.full_messages).to eq(['E00003 Broken'])
  end
  
  context 'Hold' do

    it 'should enqueue a transaction when held' do
      expect { user.hold(1.00, user.payments.default).save }.to have_enqueued_job
    end

    it 'should have errors if the hold amount is invalid' do
      hold = user.hold(0, user.payments.default)
      expect(hold).to_not be_valid
      hold.amount = 0.1
      expect(hold).to be_valid
    end

    it 'should have errors if the payment method is invalid' do
      hold = user.hold(1, nil)
      expect(hold).to_not be_valid
      hold.payment = user.payments.default
      expect(hold).to be_valid
    end

    it 'should raise an invalid record error if the hold amount is invalid' do
      expect { user.hold!(1, user.payments.default) }.to_not raise_error
      expect { user.hold!(0, user.payments.default) }.to raise_error(ActiveRecord::RecordInvalid, /Amount must be greater than 0/)
    end

    it 'should raise an invalid record error if the payment method is not defined' do
      expect { user.hold!(1, user.payments.default) }.to_not raise_error
      expect { user.hold!(1, nil) }.to raise_error(ActiveRecord::RecordInvalid, /Payment can't be blank/)
    end

  end

  context 'Capture' do

    let(:hold) { user.transactions.holds.last }

    it 'should enqueue a transaction when captured' do
      expect { user.capture(hold).save }.to have_enqueued_job
    end

    it 'should use the transaction amount if not explicitly defined' do
      capture = user.capture(hold)
      expect(capture.amount).to eq(hold.amount)

      amt = rand(1..999999)
      capture = user.capture(hold, amt)
      expect(capture.amount).to eq(amt)
    end

    it 'should not be valid if the hold is expired' do
      capture = user.capture(hold)
      expect(capture).to be_valid

      hold.status = :expired
      capture = user.capture(hold)
      expect(capture).to_not be_valid
    end

    it 'should not be valid if the hold is not a hold' do
      capture = user.capture(hold)
      expect(capture).to be_valid

      capture = user.capture(user.transactions.charges.last)
      expect(capture).to_not be_valid
    end

    it 'should raise an invalid record error if the hold is expired' do
      expect { user.capture!(hold) }.to_not raise_error

      hold.status = :expired
      expect { user.capture!(hold) }.to raise_error(ActiveRecord::RecordInvalid, /cannot be captured because the hold has expired/)
    end

    it 'should raise an invalid record error if the hold is not a hold' do
      expect { user.capture!(hold) }.to_not raise_error

      expect { user.capture!(user.transactions.charges.last) }.to raise_error(ActiveRecord::RecordInvalid, /cannot be captured because it is not a hold/)
    end

  end

  context 'Void' do

    it 'should enqueue a transaction when voided' do
      expect { user.void(user.transactions.charges.last).save }.to have_enqueued_job
    end

    it 'should not be valid if trying to void a non captured transaction' do
      void = user.void(user.transactions.charges.last)
      expect(void).to be_valid

      void = user.void(user.transactions.holds.last)
      expect(void).to_not be_valid
    end

    it 'should raise an invalid record error if trying to void a non captured transaction' do
      expect { user.void!(user.transactions.charges.last) }.to_not raise_error
      expect { user.void!(user.transactions.holds.last) }.to raise_error(ActiveRecord::RecordInvalid, /cannot be voided because it has not been captured/)
    end

  end

  context 'Charge' do

    it 'should enqueue a transaction when charged' do
      expect { user.charge(1.00, user.payments.default).save }.to have_enqueued_job
    end

    it 'should have errors if the charge amount is invalid' do
      charge = user.charge(0, user.payments.default)
      expect(charge).to_not be_valid

      charge.amount = 0.1
      expect(charge).to be_valid
    end

    it 'should raise an invalid record error if the charge amount is invalid' do
      expect { user.charge!(1, user.payments.default) }.to_not raise_error
      expect { user.charge!(0, user.payments.default) }.to raise_error(ActiveRecord::RecordInvalid, /Amount must be greater than 0/)
    end

  end

  context 'Refund' do

    it 'should enqueue a transaction when refunded' do
      expect { user.refund(1.00, user.transactions.charges.last, user.payments.default).save }.to have_enqueued_job
    end

    it 'should have errors if the refund amount is invalid' do
      refund = user.refund(0, user.transactions.charges.last, user.payments.default)
      expect(refund).to_not be_valid
      refund.amount = 0.1
      expect(refund).to be_valid
    end

    it 'should have errors if the refund amount is greater than the original transaction amount' do
      charge = user.transactions.charges.last
      refund = user.refund(charge.amount + 0.1, charge, user.payments.default)
      expect(refund).to_not be_valid
      refund = user.refund(charge.amount, charge, user.payments.default)
      expect(refund).to be_valid
    end

    it 'should have errors if the refund transaction has not been captured' do
      refund = user.refund(1, user.transactions.charges.last, user.payments.default)
      expect(refund).to be_valid

      refund = user.refund(1, user.transactions.holds.last, user.payments.default)
      expect(refund).to_not be_valid
    end

    it 'should raise an invalid record error if the refund amount is invalid' do
      expect { user.refund!(1, user.transactions.charges.last, user.payments.default) }.to_not raise_error
      expect { user.refund!(0, user.transactions.charges.last, user.payments.default) }.to raise_error(ActiveRecord::RecordInvalid, /Amount must be greater than 0/)
    end

    it 'should raise an invalid record error if the refund amount is greater than the original transaction amount' do
      charge = user.transactions.charges.last
      expect { user.refund!(charge.amount, charge, user.payments.default) }.to_not raise_error
      expect { user.refund!(charge.amount + 0.1, charge, user.payments.default) }.to raise_error(ActiveRecord::RecordInvalid, /cannot be greater than the original transaction amount/)
    end

    it 'should raise an invalid record error if the refund transaction has not been captured' do
      expect { user.refund!(1, user.transactions.charges.last, user.payments.default) }.to_not raise_error
      expect { user.refund!(1, user.transactions.holds.last, user.payments.default) }.to raise_error(ActiveRecord::RecordInvalid, /cannot be refunded because the transaction has not been captured/)
    end

  end

  context 'Subscribe' do

    it 'should enqueue a transaction when subscribed' do
      expect { user.subscribe('Test Subscription', 1.00, 6, user.payments.default).save }.to have_enqueued_job
    end

    it 'should have errors if the name is not defined' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default)
      expect(subscription).to be_valid

      subscription.name = nil
      expect(subscription).to_not be_valid
    end

    it 'should have errors if the length is not present' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default)
      expect(subscription).to be_valid

      subscription.length = nil
      expect(subscription).to_not be_valid

      subscription.length = 0
      expect(subscription).to_not be_valid
    end

    it 'should have errors if the start date is blank' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default)
      expect(subscription).to be_valid

      subscription.start_date = nil
      expect(subscription).to_not be_valid
    end

    it 'should have errors if the amount is less than or equal to zero' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default)
      expect(subscription).to be_valid

      subscription.amount = 0
      expect(subscription).to_not be_valid
    end

    it 'should have errors if the trial occurrences is less than or equal to zero' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default, trial_occurrences: 1)
      expect(subscription).to be_valid

      subscription.trial_occurrences = 0
      expect(subscription).to_not be_valid
    end

    it 'should have errors if the trial occurrences is not a whole number' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default, trial_occurrences: 1)
      expect(subscription).to be_valid

      subscription.trial_occurrences = 1.1
      expect(subscription).to_not be_valid
    end

    it 'should validate the trial amount only if the trial occurrences is set' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default, trial_amount: -1)
      expect(subscription).to be_valid

      subscription.trial_occurrences = 1
      expect(subscription).to_not be_valid
    end

    it 'should have errors if the trial amount is less than zero' do
      subscription = user.subscribe('Test Subscription', 1.00, 6, user.payments.default, trial_amount: 1, trial_occurrences: 1)
      expect(subscription).to be_valid

      subscription.trial_amount = -1
      expect(subscription).to_not be_valid
    end

    it 'should raise an invalid record error for all errors if the bang method is used' do
      expect { user.subscribe('Test Subscription', 1.00, 1, user.payments.default) }.to_not raise_error
      expect { user.subscribe!(nil, 1.00, 1, user.payments.default) }.to raise_error(ActiveRecord::RecordInvalid)
    end

  end

end
