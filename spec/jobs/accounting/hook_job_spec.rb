require 'spec_helper'

RSpec.describe Accounting::HookJob, type: :job do

  include ActiveJob::TestHelper

  let(:valid_signature) { '0F6CE5553D27622F6BA93BA1D1DF1541AA29E912881D8AD364F41C07BB2EC4F6697BF7625D9F37B41E4046799A91B5B4B4084ADC892DDB17EF8E88CA0B829528' }
  let(:invalid_signature) { 'BOLOGNE' }

  let(:body) { '{"notificationId":"4985a7ab-0503-428c-bc0d-e034b83e7be7","eventType":"net.authorize.customer.paymentProfile.created","eventDate":"2018-10-18T03:09:30.2729756Z","webhookId":"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc","payload":{"customerProfileId":1915926376,"entityName":"customerPaymentProfile","id":"1829278584"}}' }
  let(:valid_payload) { {"notificationId"=>"4985a7ab-0503-428c-bc0d-e034b83e7be7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-18T03:09:30.2729756Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915926376, "entityName"=>"customerPaymentProfile", "id"=>"1829278584"} } }
  let(:invalid_payload) { {"notificationId"=>"4985a7ab-0503-428c-bc0d-e034b83e7be7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-18T03:09:30.2729756Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915926376, "entityName"=>"customerPaymentProfile", "id"=>"1111111111"} } }

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
