require 'spec_helper'

RSpec.describe Accounting::Subscription, type: :model do

  before(:all) { ActiveJob::Base.queue_adapter = :test }

  let!(:user) { FactoryBot.create(:user) }
  let!(:payment) { FactoryBot.build(:accounting_payment, :with_card, profile: user.profile) }

  before :each { skip }

  it 'should support instantiation' do
    expect(Accounting::Subscription.new).to be_instance_of(Accounting::Subscription)
  end

  it 'should enqueue a subscription' do
    subscription = user.subscribe('Test', 1.00, 6, user.payments.default)
    VCR.use_cassette :valid_subscription do
      expect { subscription.save }.to have_enqueued_job
    end
  end

  it 'should be able to be processed manually' do
    subscription = user.subscribe('Test', 1.00, 6, user.payments.default)
    expect(subscription.job_id).to be_nil

    VCR.use_cassette :valid_subscription do
      subscription.process_now
    end
    expect(subscription.job_id).to eq('0')
  end

  it 'should be cancelable' do
    subscription = user.subscribe('Test', 2.00, 6, user.payments.default)
    subscription.save!
    sleep 10
    subscription.process_now!

    expect(subscription.cancel).to eq(true)
  end

  it 'should return true when canceled if already canceled' do
    subscription = user.subscribe('Test', 2.00, 6, user.payments.default)

    VCR.use_cassette :valid_subscription do
      subscription.process_now!
    end

    subscription.update(status: :canceled)

    expect(subscription.cancel).to eq(true)
  end

  it 'should have errors if not cancelable' do
    subscription = user.subscribe('Test', 1.00, 6, user.payments.default)

    VCR.use_cassette :valid_subscription do
      subscription.process_now!
    end

    subscription.update(subscription_id: '1234567890')
    expect(subscription.cancel).to eq(false)
    expect(subscription.errors).to_not be_blank
  end

  it 'should raise an error if not cancelable' do
    subscription = user.subscribe('Test', 1.00, 6, user.payments.default)

    VCR.use_cassette :valid_subscription do
      subscription.process_now!
    end

    subscription.update(subscription_id: '1234567890')
    expect { subscription.cancel! }.to raise_error(StandardError)
  end

  it 'should log an already canceled message if already canceled' do
    subscription = user.subscribe('Test', 1.00, 6, user.payments.default)

    VCR.use_cassette :valid_subscription do
      subscription.process_now!
    end

    subscription.update(status: :canceled)

    Accounting.config.cancel_subscription_on_destroy = true
    expect(Accounting.config.logger).to receive(:warn).with(/has already been canceled/)
    subscription.destroy
  end

  it 'should have errors if unable to process' do
    subscription = user.subscribe('Test', 1.00, 6, user.payments.default)

    VCR.use_cassette :invalid_subscription do
      subscription.save!
      expect(subscription.process_now).to eq(false)
    end

    expect(subscription.errors.full_messages).to eq(["E00040 The record cannot be found."])
  end

  it 'should have an error about prior cancelation if already canceled' do
    subscription = user.subscribe('Test', 4.00, 6, user.payments.default)
    subscription.save!
    sleep 10
    subscription.process_now!
    expect(subscription.cancel).to eq(true)
    expect { subscription.cancel! }.to raise_error(::Accounting::SubscriptionCanceledError)
  end

  it 'will cancel the subscription when destroyed, if config allows' do
    Accounting.config.cancel_subscription_on_destroy = false
    subscription1 = user.subscribe('Test', 5.00, 6, user.payments.default)
    subscription1.save!
    sleep 10
    subscription1.process_now!

    expect(subscription1).to_not receive(:cancel!)
    subscription1.destroy!

    subscription2 = user.subscribe('Test', 6.00, 6, user.payments.default)
    subscription2.save!
    sleep 10
    subscription2.process_now!

    Accounting.config.cancel_subscription_on_destroy = true
    expect(subscription2).to receive(:cancel!)
    subscription2.destroy!

    subscription3 = user.subscribe('Test', 7.00, 6, user.payments.default)
    subscription3.save!
    sleep 10
    subscription3.process_now!

    subscription3.update(status: AuthorizeNet::ARB::Subscription::Status::CANCELED)

    expect(subscription3).to receive(:cancel!)
    expect { subscription3.destroy! }.to_not raise_error

    subscription4 = user.subscribe('Test', 8.00, 6, user.payments.default)
    subscription4.save!
    sleep 10
    subscription4.process_now!

    subscription4.update(subscription_id: '1234567890')

    expect { subscription4.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
  end

  it 'should raise a duplicate transaction error if subscription already exists' do
    subscription5 = user.subscribe('Test', 10.00, 6, user.payments.default)
    subscription5.save!
    sleep 10
    subscription5.process_now!

    subscription2 = user.subscribe('Test', 10.00, 6, user.payments.default)
    subscription2.save!
    sleep 10
    expect { subscription2.process_now! }.to raise_error(::Accounting::DuplicateError)
  end

  it 'should flag the subscription as a duplicate' do
    subscription6 = user.subscribe('Test', 11.00, 6, user.payments.default)
    subscription6.submitted_at = Time.now
    subscription6.subscription_id = '1234567890'
    subscription6.save!
    expect(subscription6.status).to eq('pending')
    subscription6.process_now
    expect(subscription6.status).to eq('duplicate')
  end

  it 'should have a next transaction date' do
    subscription7 = user.subscribe('Test', 12.00, 7, user.payments.default, start_date: Time.new(2017, 1, 31), total_occurrences: 2, unit: :days)
    subscription7.save!

    expect(subscription7.next_transaction_date.beginning_of_day).to eq(Time.new(2017, 2, 7).in_time_zone('UTC').beginning_of_day)
  end

  it 'should have a next transaction date at the end of the month if a month does not have as many days as the start month' do
    subscription8 = user.subscribe('Test', 13.00, 1, user.payments.default, start_date: Time.new(2017, 1, 31), total_occurrences: 2, unit: :months)
    subscription8.save!

    expect(subscription8.next_transaction_date.beginning_of_day).to eq(Time.new(2017, 2, 28).in_time_zone('UTC').beginning_of_day)
  end

end
