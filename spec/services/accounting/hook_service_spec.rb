require 'spec_helper'

RSpec.describe Accounting::HookService do

  let(:profile) { FactoryBot.create(:accounting_profile) }
  let(:hook) { Accounting::HookService.new({ 'payload' => { 'entityName' => 'transaction' }, 'eventType' => 'create' }, TEST_UID) }

  before(:each) do
    profile.update_column(:profile_id, 1502474889)
  end

  it 'will have a titleized entity name' do
    hook.payload[:entity_name] = 'transaction'
    expect(hook.entity_name).to eq('Transaction')

    hook.payload[:entity_name] = 'subscription'
    expect(hook.entity_name).to eq('Subscription')

    hook.payload[:entity_name] = 'customerProfile'
    expect(hook.entity_name).to eq('Customer Profile')

    hook.payload[:entity_name] = 'customerPaymentProfile'
    expect(hook.entity_name).to eq('Customer Payment Profile')

    hook.payload[:entity_name] = nil
    expect(hook.entity_name).to eq('Unknown')
  end

  it 'will have a service if the entity is one of four possible options' do
    hook.payload[:entity_name] = 'transaction'
    expect(hook.has_service?).to eq(true)
    expect(hook.service).to be_instance_of(Accounting::TransactionService)

    hook.payload[:entity_name] = 'subscription'
    expect(hook.has_service?).to eq(true)
    expect(hook.service).to be_instance_of(Accounting::SubscriptionService)

    hook.payload[:entity_name] = 'customerProfile'
    expect(hook.has_service?).to eq(true)
    expect(hook.service).to be_instance_of(Accounting::ProfileService)

    hook.payload[:entity_name] = 'customerPaymentProfile'
    expect(hook.has_service?).to eq(true)
    expect(hook.service).to be_instance_of(Accounting::PaymentService)

    hook.payload[:entity_name] = 'bologne'
    expect(hook.has_service?).to eq(false)
  end

end