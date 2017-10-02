require 'spec_helper'

RSpec.describe Accounting::HookJob, type: :job do

  include ActiveJob::TestHelper

  let(:valid_signature) { '9DE493FA0B3FF24708AB26D33B7A52E321C4B3D6987AFE6CCF3F5E97C16649BF62403A3ACAF0C317E58DF7F012A6DD3FD6364ED08284988A62112148931E05B1' }
  let(:invalid_signature) { 'BOLOGNE' }

  let(:body) { '{"notificationId":"d57e72c5-5e4a-418b-a0f5-ed7f5b39258d","eventType":"net.authorize.customer.paymentProfile.created","eventDate":"2017-09-22T22:10:10.5591051Z","webhookId":"82ed4771-17bb-4fc6-8ea4-f0cad81d3414","payload":{"customerProfileId":1502483854,"entityName":"customerPaymentProfile","id":"1502013436"}}' }
  let(:valid_payload) { { "notificationId" => "d57e72c5-5e4a-418b-a0f5-ed7f5b39258d", "eventType" => "net.authorize.customer.paymentProfile.created", "eventDate" => "2017-09-22T22:10:10.5591051Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "customerProfileId" => 1502483854, "entityName" => "customerPaymentProfile", "id" => "1502013436" } } }
  let(:invalid_payload) { { "notificationId" => "d57e72c5-5e4a-418b-a0f5-ed7f5b39258d", "eventType" => "net.authorize.customer.paymentProfile.created", "eventDate" => "2017-09-22T22:10:10.5591051Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "customerProfileId" => 1502483854, "entityName" => "customerPaymentProfile", "id" => "1111111111" } } }

  subject(:valid_job) { described_class.perform_later(valid_signature, body, valid_payload) }
  subject(:invalid_job) { described_class.perform_later(invalid_signature, body, valid_payload) }
  subject(:invalid_payload_job) { described_class.perform_later(valid_signature, body, invalid_payload) }

  it 'will queue the transaction job' do
    expect { valid_job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it 'will perform the hook task' do
    expect_any_instance_of(Accounting::HookService).to receive(:handle!)
    perform_enqueued_jobs { valid_job }
  end

  it 'will log a sync error if the hook fails authentication' do
    expect(Accounting.config.logger).to receive(:error).with(/Invalid signature/)
    perform_enqueued_jobs { invalid_job }
  end

  it 'will log a sync warning if the hook fails to process' do
    expect(Accounting.config.logger).to receive(:warn)
    expect { perform_enqueued_jobs { invalid_payload_job } }.to raise_error(Accounting::SyncWarning)
  end

end
