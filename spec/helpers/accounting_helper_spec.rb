require 'spec_helper'

RSpec.describe AccountingHelper, type: :helper do

  let(:user) { FactoryGirl.create(:user, name: 'Test Name', email: 'test_email@example.org') }

  it 'will return the value returned from a proc argument' do
    expect(value_from(proc { |u| u.name }, user, user)).to eq('Test Name')
    expect(value_from(proc { |u| u.email }, user, user)).to eq('test_email@example.org')
  end

  it 'will return the value from a method matching the given symbol argument' do
    expect(value_from(:name, user)).to eq('Test Name')
    expect(value_from(:email, user)).to eq('test_email@example.org')
  end

  it 'will return the original argument if the original argument is a string' do
    expect(value_from('name', user, user)).to eq('name')
    expect(value_from('email', user, user)).to eq('email')
  end

  it 'should raise an argument error if the argument defining the callback is not a proc/lambda, string, or symbol' do
    expect { value_from(1, user) }.to raise_error(ArgumentError)
  end

end
