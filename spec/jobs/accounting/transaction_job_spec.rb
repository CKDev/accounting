require 'spec_helper'

RSpec.describe Accounting::TransactionJob, type: :job do

  include ActiveJob::TestHelper

  let(:user) { FactoryGirl.create(:user, :with_payment) }

  let(:transaction) do
    transaction = user.charge(1.00, user.payments.default)
    transaction.job_id = '0' # Will prevent process_later from being triggered
    transaction.save
    transaction
  end

  subject(:job) { described_class.perform_later(transaction) }

  it 'will queue the transaction job' do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'will perform the transaction task' do
    expect_any_instance_of(Accounting::Transaction).to receive(:process_now!)
    perform_enqueued_jobs { job }
  end

end
