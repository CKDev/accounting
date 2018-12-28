require 'spec_helper'

RSpec.describe Accounting::ProfileService do

  let(:profile) { FactoryGirl.create(:accounting_profile) }
  let(:hook_profile)          { {"notificationId"=>"16b7f322-5914-41af-99bc-26095ba7f2e7", "eventType"=>"net.authorize.customer.created", "eventDate"=>"2018-10-17T16:00:46.5489933Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"merchantCustomerId"=>"051562a2", "description"=>"Test Description", "entityName"=>"customerProfile", "id"=>"1915911486"}, "hook"=>{"notificationId"=>"16b7f322-5914-41af-99bc-26095ba7f2e7", "eventType"=>"net.authorize.customer.created", "eventDate"=>"2018-10-17T16:00:46.5489933Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"merchantCustomerId"=>"051562a2", "description"=>"Test Description", "entityName"=>"customerProfile", "id"=>"1915911486"}}} }

  let(:service_profile)       { Accounting::HookService.new(hook_profile, TEST_UID).service }

  before(:each) do
    profile.update_column(:profile_id, 1502474889)
    if service_profile.resource.nil?
      skip 'Please input valid webhook and customer profile id with paymentProfiles'
    end
  end

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
    expect { service_profile.sync! }.to change { Accounting::Payment.count }.by(hook_profile['payload']['paymentProfiles'].count)
  end

  it 'should raise a sync error if the profile cannot be found in authorize.net' do
    expect { service_profile.sync! }.to_not raise_error

    service_profile.payload[:id] = nil
    service_profile.instance_variable_set('@resource', nil)

    expect { service_profile.sync! }.to raise_error(Accounting::SyncError, /Customer profile cannot be created/)
  end

  it 'should destroy the profile record if sync event is "deleted"' do
    service_profile.sync! # Create resource
    service_profile.event = 'deleted'
    expect { service_profile.sync! }.to change { Accounting::Profile.count }.by(-1) # Now destroy it
  end

end
