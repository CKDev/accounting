require 'spec_helper'

RSpec.describe Accounting::SubscriptionJob, type: :job do

  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user, :with_payment) }
  before(:each) { skip }
  let(:subscription) do
    subscription = user.subscribe('Test', 4.00, 6, user.payments.default)
    subscription.job_id = '0' # Will prevent process_later from being triggered
    subscription.save
    subscription
  end

  subject(:job) { described_class.perform_later(subscription) }

  it 'will queue the subscription job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'will perform the subscription job' do
    expect_any_instance_of(Accounting::Subscription).to receive(:process_now!)
    perform_enqueued_jobs { job }
  end

end
