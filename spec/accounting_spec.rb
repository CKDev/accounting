require 'spec_helper'

RSpec.describe Accounting do

  it 'has a version number' do
    expect(Accounting::VERSION).not_to be nil
  end

  it 'has a sync error class that provides access to the payload' do
    error = Accounting::SyncError.new('Error')
    expect(error.payload).to eq({})

    error = Accounting::SyncError.new('Error', { payload: 1 })
    expect(error.payload).to eq({ payload: 1 })
  end

  it 'has a sync warning class that provides access to the payload' do
    error = Accounting::SyncWarning.new('Warning')
    expect(error.payload).to eq({})

    error = Accounting::SyncWarning.new('Warning', { payload: 1 })
    expect(error.payload).to eq({ payload: 1 })
  end

  it 'will log messages even if logger does not support tagged logging' do
    expect(Accounting.config.logger).to respond_to(:tagged)
    expect(Accounting.config.logger).to receive(:error).with('Test 1')
    Accounting.log('Tag 1', 'Tag 2', 'Tag 3', error: 'Test 1')

    Accounting.config.logger = Logger.new(Rails.root.join('log', 'accounting.log'), 'weekly')

    expect(Accounting.config.logger).to_not respond_to(:tagged)
    expect(Accounting.config.logger).to receive(:warn).with(/Test 2$/)
    Accounting.log('Tag 1', 'Tag 2', 'Tag 3', warn: 'Test 2')
  end

end
