require 'spec_helper'

RSpec.describe Accounting::PaymentService do

  let(:profile) { FactoryBot.create(:accounting_profile) }

  let(:hook_profile)          { {"notificationId"=>"16b7f322-5914-41af-99bc-26095ba7f2e7", "eventType"=>"net.authorize.customer.created", "eventDate"=>"2018-10-17T16:00:46.5489933Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"merchantCustomerId"=>"051562a2", "description"=>"Test Description", "entityName"=>"customerProfile", "id"=>"1916962958"}, "hook"=>{"notificationId"=>"16b7f322-5914-41af-99bc-26095ba7f2e7", "eventType"=>"net.authorize.customer.created", "eventDate"=>"2018-10-17T16:00:46.5489933Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"merchantCustomerId"=>"051562a2", "description"=>"Test Description", "entityName"=>"customerProfile", "id"=>"1916962958"}}} }
  let(:hook_payment_card)     { {"notificationId"=>"9a8c85fc-ac8f-460e-84a7-cc4c963711a7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:30:02.2270619Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1916962958, "entityName"=>"customerPaymentProfile", "id"=>"1830218375"}, "hook"=>{"notificationId"=>"9a8c85fc-ac8f-460e-84a7-cc4c963711a7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:30:02.2270619Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1916962958, "entityName"=>"customerPaymentProfile", "id"=>"1830218375"}}} }
  let(:hook_payment_ach)      { {"notificationId"=>"4c8711d3-3cf5-4953-afe7-805dcd595103", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:27:56.8906329Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1916962958, "entityName"=>"customerPaymentProfile", "id"=>"1505662018"}, "hook"=>{"notificationId"=>"4c8711d3-3cf5-4953-afe7-805dcd595103", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:27:56.8906329Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1916962958, "entityName"=>"customerPaymentProfile", "id"=>"1505662018"}}} }

  let(:service_profile)       { Accounting::HookService.new(hook_profile, TEST_UID).service }
  let(:service_payment_card)  { Accounting::HookService.new(hook_payment_card, TEST_UID).service }
  let(:service_payment_ach)   { Accounting::HookService.new(hook_payment_ach, TEST_UID).service }

  before(:each) do
    profile.update_column(:profile_id, 1916962958)
    if service_profile.resource.nil?
      skip 'Please input valid webhook and customer payment profile id'
    end
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

    service_payment_card.resource.profile.delete
    service_payment_card.resource.profile_id = nil

    expect { service_payment_card.sync! }.to raise_error(Accounting::SyncWarning, /Payment profile cannot be created, profile with profile id/)
  end

  # it 'should accurately know the type of payment profile' do
  #   service_payment_card.sync!
  #   service_payment_ach.sync!
  #   expect(service_payment_card.type).to eq(:card)
  #   expect(service_payment_card.card?).to eq(true)
  #   expect(service_payment_ach.type).to eq(:ach)
  #   expect(service_payment_ach.ach?).to eq(true)
  # end

  it 'should destroy the payment profile record if sync event is "deleted"' do
    service_payment_card.sync! # Create resource
    service_payment_card.event = 'deleted'
    expect_any_instance_of(Accounting::Payment).to receive(:delete_payment)
    service_payment_card.sync!
    # expect { service_payment_card.sync! }.to change { Accounting::Payment.count }.by(-1) # Now destroy it
  end

  it 'should raise a sync error if the payment details could not be found' do
    service_payment_card.sync!
    service_payment_card.resource.update_column(:payment_profile_id, nil)
    service_payment_card.resource.profile.update_column(:profile_id, nil)
    service_payment_card.resource.instance_variable_set('@response', nil)
    expect { service_payment_card.details }.to raise_error(Accounting::SyncError, /Payment profile cannot be created because the record could not be found/)
  end
end
