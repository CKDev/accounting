require 'spec_helper'

RSpec.describe User, type: :model do

  let(:accountable) { User.new }
  let(:profile) { FactoryBot.create(:accounting_profile) }
  let(:profile_id) { profile.profile_id }

  it 'should create a profile on save' do
    expect do
      accountable.save
    end.to change(Accounting::Profile, :count).by(1)
  end

  it 'should create profile with specified profile ID' do
    profile.delete
    accountable.existing_profile_id = profile.profile_id

    accountable.save
    expect(accountable.profile.profile_id).to eq(profile.profile_id)
  end

end
