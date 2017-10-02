require 'spec_helper'

RSpec.describe Accounting::SubscriptionService do

  let(:hook_profile)          { { "notificationId" => "e2eaa2bd-4c5f-4bb8-a943-da264a0b1968", "eventType" => "net.authorize.customer.created", "eventDate" => "2017-09-20T17:18:54.9460311Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "paymentProfiles" => [{ "id" => "1501998893" }], "merchantCustomerId" => "2b86c057-d7fe-4d57-a", "description" => "Ipsam quam voluptatem sunt et dolorum.", "entityName" => "customerProfile", "id" => "1502474889" }} }
  let(:hook_payment)          { { "notificationId" => "35f96318-03c4-419e-922f-2b0fb561b885", "eventType" => "net.authorize.customer.paymentProfile.created", "eventDate" => "2017-09-21T04:45:36.437607Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "customerProfileId" => 1502473210, "entityName" => "customerPaymentProfile", "id" => "1501998893" }} }
  let(:hook_subscription)     { { "notificationId" => "d68c0825-5ba8-40b9-97db-f16274731fab", "eventType" => "net.authorize.customer.subscription.created", "eventDate" => "2017-09-21T19:57:18.9398092Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "name" => "Test", "amount" => 4.0, "status" => "canceled", "profile" => {"customerProfileId" => 1502474889, "customerPaymentProfileId" => 1501998893}, "entityName" => "subscription", "id" => "4765887"}, "hook"=>{"notificationId" => "d68c0825-5ba8-40b9-97db-f16274731fab", "eventType" => "net.authorize.customer.subscription.created", "eventDate" => "2017-09-21T19:57:18.9398092Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"name" => "Test", "amount"=>4.0, "status" => "canceled", "profile" => {"customerProfileId" => 1502474889, "customerPaymentProfileId" => 1501998893}, "entityName" => "subscription", "id" => "4765887" }}} }

  let(:service_profile)       { Accounting::HookService.new(hook_profile).service }
  let(:service_payment)       { Accounting::HookService.new(hook_payment).service }
  let(:service_subscription)  { Accounting::HookService.new(hook_subscription).service }

  before(:each) do
    service_profile.sync!
  end

  it 'should be instantiable' do
    expect(service_subscription).to be_instance_of(Accounting::SubscriptionService)
  end

  it 'should have a resource with a profile relation after syncing' do
    expect(service_subscription.resource.profile_id).to be_nil

    service_subscription.sync!

    expect(service_subscription.resource.profile_id).to_not be_nil
  end

  it 'should raise a sync warning of the associated profile cannot be found' do
    expect { service_subscription.profile }.to_not raise_error

    service_subscription.profile.destroy

    expect { service_subscription.profile }.to raise_error(Accounting::SyncWarning, /Subscription cannot be created, profile with id/)
  end

  it 'should raise a sync warning of the associated payment cannot be found' do
    service_subscription.sync!
    expect { service_subscription.payment }.to_not raise_error

    service_subscription.resource.profile.payments.destroy_all

    expect { service_subscription.payment }.to raise_error(Accounting::SyncWarning, /Subscription cannot be created because the defined payment method was not found on the accountable profile/)
  end

  it 'should destroy the subscription record if sync event is "deleted"' do
    service_subscription.sync! # Create resource
    service_subscription.event = 'deleted'
    service_subscription.resource.update(status: :active) # Ensure status is active so it can be canceled
    expect { service_subscription.sync! }.to change { Accounting::Subscription.count }.by(-1) # Now destroy it
  end

  it 'should raise a sync error if the subscription details could not be found' do
    service_subscription.sync!
    service_subscription.resource.update_column(:subscription_id, nil)
    service_subscription.resource.instance_variable_set('@details', nil)
    expect { service_subscription.details }.to raise_error(Accounting::SyncError, /Subscription cannot be created because the record could not be found/)
  end
end