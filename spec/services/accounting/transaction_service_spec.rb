require 'spec_helper'

RSpec.describe Accounting::TransactionService do

  let(:profile) { FactoryGirl.create(:accounting_profile) }
  let(:hook_card)             { {"notificationId"=>"9a8c85fc-ac8f-460e-84a7-cc4c963711a7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:30:02.2270619Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915911486, "entityName"=>"customerPaymentProfile", "id"=>"1829269244"}, "hook"=>{"notificationId"=>"9a8c85fc-ac8f-460e-84a7-cc4c963711a7", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:30:02.2270619Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915911486, "entityName"=>"customerPaymentProfile", "id"=>"1829269244"}}} }
  let(:hook_ach)              { {"notificationId"=>"4c8711d3-3cf5-4953-afe7-805dcd595103", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:27:56.8906329Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915911486, "entityName"=>"customerPaymentProfile", "id"=>"1829269233"}, "hook"=>{"notificationId"=>"4c8711d3-3cf5-4953-afe7-805dcd595103", "eventType"=>"net.authorize.customer.paymentProfile.created", "eventDate"=>"2018-10-17T16:27:56.8906329Z", "webhookId"=>"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc", "payload"=>{"customerProfileId"=>1915911486, "entityName"=>"customerPaymentProfile", "id"=>"1829269233"}}} }
  let(:hook_subscription)     { { "notificationId" => "13739aed-1ac2-4611-9c59-38ea8abd6ed0", "eventType" => "net.authorize.payment.authcapture.created", "eventDate" => "2017-09-20T17:22:06.6624919Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"responseCode" => 0,"authCode" => "YSV1DM", "avsResponse" => "Y", "authAmount" => 0.0, "entityName" => "transaction", "id" => "60030156528" }} }
  let(:hook_unknown)          { { "notificationId" => "13739aed-1ac2-4611-9c59-38ea8abd6ed0", "eventType" => "net.authorize.payment.authcapture.created", "eventDate" => "2017-09-20T17:22:06.6624919Z", "webhookId" => "82ed4771-17bb-4fc6-8ea4-f0cad81d3414", "payload" => {"responseCode" => 0,"authCode" => "YSV1DM", "avsResponse" => "Y", "authAmount" => 0.0, "entityName" => "transaction", "id" => "40007191118" }} }

  let(:service_card)          { Accounting::HookService.new(hook_card).service }
  let(:service_ach)           { Accounting::HookService.new(hook_ach).service }
  let(:service_subscription)  { Accounting::HookService.new(hook_subscription).service }
  let(:service_unknown)       { Accounting::HookService.new(hook_unknown).service }

  let(:profile)               { Accounting::Profile.create!(authnet_email: service_card.resource.details.customer.email, profile_id: 1) }
  let(:profile_subscription)  { Accounting::Profile.create!(authnet_email: service_subscription.resource.details.customer.email, profile_id: 2) }

  before(:each) do
    profile.update_column(:profile_id, 1502474889)
    payment_card              = Accounting::Payment.create!(profile_id: profile.id, profile_type: :card, last_four: service_card.last_four, month: 1, year: 2080, payment_profile_id: 1, address_attributes: { first_name: 'Test', last_name: 'Tester', street_address: '123 Fake St', city: 'Denver', state: 'CO', zip: '11111', address_id: 1 })
    payment_ach               = Accounting::Payment.create!(profile_id: profile.id, profile_type: :ach, routing: '1111111111', account: '222222222', bank_name: 'Test Bank', account_holder: 'Test Tester', account_type: 'checking', last_four: service_ach.last_four, payment_profile_id: 2, address_attributes: { first_name: 'Test', last_name: 'Tester', street_address: '123 Fake St', city: 'Denver', state: 'CO', zip: '11111', address_id: 2 })
    payment_subscription_card = Accounting::Payment.create!(profile_id: profile_subscription.id, profile_type: :card, last_four: service_subscription.last_four, month: 1, year: 2080, payment_profile_id: 3, address_attributes: { first_name: 'Test', last_name: 'Tester', street_address: '123 Fake St', city: 'Denver', state: 'CO', zip: '11111', address_id: 3 })
    payment_subscription_ach  = Accounting::Payment.create!(profile_id: profile_subscription.id, profile_type: :ach, routing: '1111111111', account: '222222222', bank_name: 'Test Bank', account_holder: 'Test Tester', account_type: 'checking', last_four: service_subscription.last_four, payment_profile_id: 4, address_attributes: { first_name: 'Test', last_name: 'Tester', street_address: '123 Fake St', city: 'Denver', state: 'CO', zip: '11111', address_id: 4 })
    subscription              = Accounting::Subscription.create!(profile_id: profile_subscription.id, subscription_id: service_subscription.resource.details.subscription_id.to_i, name: 'Test', start_date: Time.now, payment_id: payment_card.id, length: 1, unit: :months, amount: 1, total_occurrences: 9999)
  end

  it 'should be instantiable' do
    expect(service_card).to be_instance_of(Accounting::TransactionService)
  end

  it 'should have a transaction resource' do
    expect(service_card.resource).to be_instance_of(Accounting::Transaction)
  end

  it 'should have a resource with a profile and payment relations after syncing' do
    expect(service_card.resource.profile_id).to be_nil
    expect(service_card.resource.payment_id).to be_nil

    service_card.sync!

    expect(service_card.resource.profile_id).to_not be_nil
    expect(service_card.resource.payment_id).to_not be_nil
  end

  it 'should raise a sync error if the transaction details can not be found' do
    expect { service_card.sync! }.to_not raise_error

    # Reset the details, so it's forced to re-fetch after we change the transaction id
    service_card.resource.instance_variable_set('@details', nil)
    service_card.resource.transaction_id = 1

    expect { service_card.sync! }.to raise_error(Accounting::SyncError, /record could not be found/)
  end

  it 'should have a status' do
    expect(service_card.status('voided')).to eq('voided')
    expect(service_card.status('expired')).to eq('expired')
    expect(service_card.status('declined')).to eq('declined')
    expect(service_card.status('returnedItem')).to eq('returned')
    expect(service_card.status('authorizedPendingCapture')).to eq('held')
    expect(service_card.status('FDSPendingReview')).to eq('fraud')
    expect(service_card.status('FDSAuthorizedPendingReview')).to eq('fraud')
    expect(service_card.status('failedReview')).to eq('pending')
    expect(service_card.status('approvedReview')).to eq('pending')
    expect(service_card.status('underReview')).to eq('pending')
    expect(service_card.status('capturedPendingSettlement')).to eq('captured')
    expect(service_card.status('settledSuccessfully')).to eq('captured')
    expect(service_card.status('refundSettledSuccessfully')).to eq('refunded')
    expect(service_card.status('refundPendingSettlement')).to eq('refunded')
    expect(service_card.status('communicationError')).to eq('error')
    expect(service_card.status('couldNotVoid')).to eq('error')
    expect(service_card.status('generalError')).to eq('error')
    expect(service_card.status('settlementError')).to eq('error')
    expect(service_card.status('communicationError')).to eq('error')
    expect(service_card.status('bologne')).to eq('pending')
  end

  it 'should identify subscription related transactions' do
    expect(service_card.subscription?).to eq(false)
    expect(service_ach.subscription?).to eq(false)
    expect(service_subscription.subscription?).to eq(true)
  end

  it 'should associate the transaction with a subscription if provided' do
    expect(service_subscription.resource.subscription_id).to be_nil
    expect(service_subscription.resource.subscription_payment).to be_nil

    service_subscription.sync!

    expect(service_subscription.resource.subscription_id).to eq(profile_subscription.subscriptions.last.id)
    expect(service_subscription.resource.subscription_payment).to eq(1)
  end

  it 'should raise a sync warning of the associated profile cannot be found' do
    expect { service_unknown.profile }.to raise_error(Accounting::SyncWarning, /Transaction cannot be created, profile with email/)
  end

  it 'should raise a sync warning of the associated payment cannot be found' do
    service_subscription.sync!
    service_subscription.resource.profile.payments.destroy_all
    expect { service_subscription.payment }.to raise_error(Accounting::SyncWarning, /Transaction cannot be created because the defined payment method was not found on the accountable profile/)
  end

end
