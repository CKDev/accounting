require 'spec_helper'

RSpec.describe Accounting::PaymentService do

  let(:hook_profile)          { { "notificationId" => "e2eaa2bd-4c5f-4bb8-a943-da264a0b1968", "eventType" => "net.authorize.customer.created", "eventDate" => "2017-09-20T17:18:54.9460311Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"paymentProfiles" => [], "merchantCustomerId" => "2b86c057-d7fe-4d57-a", "description" => "Ipsam quam voluptatem sunt et dolorum.", "entityName" => "customerProfile", "id" => "1502473210" }} }
  let(:hook_payment_card)     { { "notificationId" => "35f96318-03c4-419e-922f-2b0fb561b885", "eventType" => "net.authorize.customer.paymentProfile.created", "eventDate" => "2017-09-21T04:45:36.437607Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"customerProfileId" => 1502473210, "entityName" => "customerPaymentProfile", "id" => "1501996571" }} }
  let(:hook_payment_ach)      { { "notificationId" => "35f96318-03c4-419e-922f-2b0fb561b885", "eventType" => "net.authorize.customer.paymentProfile.created", "eventDate" => "2017-09-21T04:45:36.437607Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"customerProfileId" => 1502473210, "entityName" => "customerPaymentProfile", "id" => "1807755575" }} }

  let(:service_profile)       { Accounting::HookService.new(hook_profile).service }
  let(:service_payment_card)  { Accounting::HookService.new(hook_payment_card).service }
  let(:service_payment_ach)   { Accounting::HookService.new(hook_payment_ach).service }

  before(:each) do
    service_profile.sync!
  end

  it 'should be instantiable' do
    expect(service_payment_card).to be_instance_of(Accounting::PaymentService)
  end

  it 'should have a resource with a profile relation after syncing' do
    expect(service_payment_card.resource.profile_id).to be_nil

    service_payment_card.sync!

    expect(service_payment_card.resource.profile_id).to_not be_nil
  end

  it 'should raise a sync error if the associated profile is not found' do
    expect { service_payment_card.sync! }.to_not raise_error

    Accounting::Profile.destroy_all
    service_payment_card.resource.profile_id = nil

    expect { service_payment_card.sync! }.to raise_error(Accounting::SyncWarning, /Payment profile cannot be created, profile with profile id/)
  end

  it 'should accurately know the type of payment profile' do
    service_payment_card.sync!
    service_payment_ach.sync!
    expect(service_payment_card.type).to eq(:card)
    expect(service_payment_card.card?).to eq(true)
    expect(service_payment_ach.type).to eq(:ach)
    expect(service_payment_ach.ach?).to eq(true)
  end

  it 'should destroy the payment profile record if sync event is "deleted"' do
    service_payment_card.sync! # Create resource
    service_payment_card.event = 'deleted'
    expect { service_payment_card.sync! }.to change { Accounting::Payment.count }.by(-1) # Now destroy it
  end

  it 'should raise a sync error if the payment details could not be found' do
    service_payment_card.sync!
    service_payment_card.resource.update_column(:payment_profile_id, nil)
    service_payment_card.resource.instance_variable_set('@details', nil)
    expect { service_payment_card.details }.to raise_error(Accounting::SyncError, /Payment profile cannot be created because the record could not be found/)
  end
end
