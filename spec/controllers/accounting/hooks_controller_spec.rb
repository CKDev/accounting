require 'spec_helper'

RSpec.describe Accounting::HooksController, type: :controller do

  let(:valid_header)    { { 'X-ANET-Signature' => 'sha512=0F6CE5553D27622F6BA93BA1D1DF1541AA29E912881D8AD364F41C07BB2EC4F6697BF7625D9F37B41E4046799A91B5B4B4084ADC892DDB17EF8E88CA0B829528' } }
  let(:invalid_header)  { { 'X-ANET-Signature' => 'sha512=2883C17E8BF62AD36C1F34C9C11FFAC38DCB7DB5661AE900F4C7549436F1797F90FDA81EF92DD0C5D967ECE2D60ACA9C55454D561F486B5E33EB7EF5766BEEA6' } }
  let(:error_header)    { { 'X-ANET-Signature' => 'sha512=5F81D8B8B6250EA6D6E3FBF4E30902708C2F5BE38FF9FB511F0350DC4F49F201BDA414B3FB718FF2372C9DF8A32C998A8E131148599237C1DECD370F1231B0F4' } }

  before(:all) { ActiveJob::Base.queue_adapter = :test }

  before(:each) do
    request.headers.merge! valid_header
    @profile = FactoryBot.create(:accounting_profile)
    @paymentProfile = FactoryBot.create(:accounting_payment, :with_ach, profile: @profile)

    @valid_payload =  "{\"notificationId\":\"4985a7ab-0503-428c-bc0d-e034b83e7be7\",
                       \"eventType\":\"net.authorize.customer.paymentProfile.created\",
                       \"eventDate\":\"2018-10-18T03:09:30.2729756Z\",
                       \"webhookId\":\"eb6e1f40-9e17-4d8d-aae3-a47acc001fbc\",
                       \"payload\":{\"customerProfileId\":#{@profile.profile_id},
                       \"description\":\"Rémy  Raleigh\",
                       \"entityName\":\"customerPaymentProfile\",
                       \"id\":#{@paymentProfile.id}}}"
  end

  it 'should enqueue a hook job on create' do
    expect { post :create, params: JSON.parse(@valid_payload).merge(uid: TEST_UID), as: :json }.to have_enqueued_job(Accounting::HookJob)
    expect(response).to have_http_status(:ok)
  end

  it 'should enqueue a hook job on update' do
    expect { post :update, params: JSON.parse(@valid_payload).merge(uid: TEST_UID) }.to have_enqueued_job(Accounting::HookJob)
    expect(response).to have_http_status(:ok)
  end

  it 'should enqueue a hook job on destroy' do
    expect { post :destroy, params: JSON.parse(@valid_payload).merge(uid: TEST_UID) }.to have_enqueued_job(Accounting::HookJob)
    expect(response).to have_http_status(:ok)
  end

#  Keep for now. Specs only needed if we're not backgrounding the request hook
#
#  it 'will reject requests that have an invalid signature' do
#    request.env['RAW_POST_DATA'] = valid_payload
#    post :create, params: JSON.parse(valid_payload)
#    expect(response).to_not have_http_status(:forbidden)
#
#    put :update, params: JSON.parse(valid_payload)
#    expect(response).to_not have_http_status(:forbidden)
#
#    delete :destroy, params: JSON.parse(valid_payload)
#    expect(response).to_not have_http_status(:forbidden)
#
#    request.env['RAW_POST_DATA'] = invalid_payload
#    post :create, params: JSON.parse(invalid_payload)
#    expect(response).to have_http_status(:forbidden)
#
#    put :update, params: JSON.parse(invalid_payload)
#    expect(response).to have_http_status(:forbidden)
#
#    delete :destroy, params: JSON.parse(invalid_payload)
#    expect(response).to have_http_status(:forbidden)
#
#    request.headers.merge! invalid_header
#    request.env['RAW_POST_DATA'] = valid_payload
#    post :create, params: JSON.parse(valid_payload)
#    expect(response).to have_http_status(:forbidden)
#
#    put :update, params: JSON.parse(valid_payload)
#    expect(response).to have_http_status(:forbidden)
#
#    delete :destroy, params: JSON.parse(valid_payload)
#    expect(response).to have_http_status(:forbidden)
#  end
#
#  it 'should respond with an internal server error if a sync warning is raised' do
#    Accounting::Profile.destroy_all
#    request.headers.merge! valid_header
#    request.env['RAW_POST_DATA'] = valid_payload
#    post :create, params: JSON.parse(valid_payload)
#    expect(response).to have_http_status(:internal_server_error)
#  end
#
#  it 'should respond with ok if a sync error is raised' do
#    request.headers.merge! invalid_header
#    request.env['RAW_POST_DATA'] = invalid_payload
#    post :create, params: JSON.parse(invalid_payload)
#    expect(response).to have_http_status(:ok)
#  end

end
