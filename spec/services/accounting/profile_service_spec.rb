require 'spec_helper'

RSpec.describe Accounting::ProfileService do

  let(:hook_profile)          { ActionController::Parameters.new({ "notificationId" => "e2eaa2bd-4c5f-4bb8-a943-da264a0b1968", "eventType" => "net.authorize.customer.created", "eventDate" => "2017-09-20T17:18:54.9460311Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => { "paymentProfiles" => [{ "id" => "1501998893" }], "merchantCustomerId" => "2b86c057-d7fe-4d57-a", "description" => "Ipsam quam voluptatem sunt et dolorum.", "entityName" => "customerProfile", "id" => "1502474889" }}) }

  let(:service_profile)       { Accounting::HookService.new(hook_profile).service }

  it 'should be instantiable' do
    expect(service_profile).to be_instance_of(Accounting::ProfileService)
  end

  it 'should sync profile specific attributes' do
    expect(service_profile.resource.authnet_id).to be_blank
    expect(service_profile.resource.authnet_email).to be_blank
    expect(service_profile.resource.authnet_description).to be_blank

    service_profile.sync!

    expect(service_profile.resource.authnet_id).to_not be_blank
    expect(service_profile.resource.authnet_email).to_not be_blank
    expect(service_profile.resource.authnet_description).to_not be_blank
  end

  it 'should create any payment methods associated with the profile' do
    expect { service_profile.sync! }.to change { Accounting::Payment.count }.by(hook_profile[:payload][:paymentProfiles].count)
  end

  it 'should raise a sync error if the profile cannot be found in authorize.net' do
    expect { service_profile.sync! }.to_not raise_error

    service_profile.payload[:id] = nil
    service_profile.instance_variable_set('@resource', nil)

    expect { service_profile.sync! }.to raise_error(Accounting::SyncError, /Customer profile with id/)
  end

  it 'should destroy the profile record if sync event is "deleted"' do
    service_profile.sync! # Create resource
    service_profile.event = 'deleted'
    expect { service_profile.sync! }.to change { Accounting::Profile.count }.by(-1) # Now destroy it
  end

end
