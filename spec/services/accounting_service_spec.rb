require 'spec_helper'

RSpec.describe AccountingService do

  let(:service) { AccountingService.new({ payload: 1 }, 'test') }

  it 'should be instantiable' do
    expect(service).to be_instance_of(AccountingService)
  end

  it 'should have a payload' do
    expect(service.payload).to eq({ payload: 1 })
  end

  it 'should have an event' do
    expect(service.event).to eq('test')
  end

  it 'should raise an accounting sync error by default' do
    expect { service.sync! }.to raise_error(Accounting::SyncError, /Method `sync!` not defined within the specific service class\./)
  end

  it 'should log sync error messages' do
    expect(Accounting.config.logger).to receive(:error).with(/Method `sync!` not defined within the specific service class\./)
    service.sync
  end

  it 'should identify delete events' do
    expect(service.delete?).to eq(false)
    service.event = 'deleted'
    expect(service.delete?).to eq(true)
  end

end