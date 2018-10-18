require 'spec_helper'

RSpec.describe Accounting::SubscriptionService do

  let(:profile) { FactoryGirl.create(:accounting_profile) }

  let(:hook_profile)          { {"notificationId"=>"16b7f322-5914-41af-99bc-26095ba7f2e7", "eventType"=>"net.authorize.customer.created", "eventDate"=>"2018-10-17T16:00:46.5489933Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"merchantCustomerId"=>"051562a2", "description"=>"Test Description", "entityName"=>"customerProfile", "id"=>"1915911486"}, "hook"=>{"notificationId"=>"16b7f322-5914-41af-99bc-26095ba7f2e7", "eventType"=>"net.authorize.customer.created", "eventDate"=>"2018-10-17T16:00:46.5489933Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"merchantCustomerId"=>"051562a2", "description"=>"Test Description", "entityName"=>"customerProfile", "id"=>"1915911486"}}} }
  let(:hook_payment)          { {"notificationId"=>"9a8c85fc-ac8f-460e-84a7-cc4c963711a7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:30:02.2270619Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915911486, "entityName"=>"customerPaymentProfile", "id"=>"1829269244"}, "hook"=>{"notificationId"=>"9a8c85fc-ac8f-460e-84a7-cc4c963711a7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:30:02.2270619Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915911486, "entityName"=>"customerPaymentProfile", "id"=>"1829269244"}}} }
  let(:hook_subscription)     { { "notificationId" => "d68c0825-5ba8-40b9-97db-f16274731fab", "eventType" => "net.authorize.customer.subscription.created", "eventDate" => "2017-09-21T19:57:18.9398092Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "name" => "Test", "amount" => 4.0, "status" => "canceled", "profile" => {"customerProfileId" => 1502474889, "customerPaymentProfileId" => 1501998893}, "entityName" => "subscription", "id" => "4765887"}, "hook"=>{"notificationId" => "d68c0825-5ba8-40b9-97db-f16274731fab", "eventType" => "net.authorize.customer.subscription.created", "eventDate" => "2017-09-21T19:57:18.9398092Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"name" => "Test", "amount"=>4.0, "status" => "canceled", "profile" => {"customerProfileId" => 1502474889, "customerPaymentProfileId" => 1501998893}, "entityName" => "subscription", "id" => "4765887" }}} }

  let(:service_profile)       { Accounting::HookService.new(hook_profile).service }
  let(:service_payment)       { Accounting::HookService.new(hook_payment).service }
  let(:service_subscription)  { Accounting::HookService.new(hook_subscription).service }

  before(:each) do
    profile.update_column(:profile_id, 1502474889)
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