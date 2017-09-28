class AccountingService

    attr_accessor :payload, :event

    def initialize(payload={}, event=nil)
      @payload = payload
      @event = event
    end

    def sync
      begin
        sync!
      rescue Accounting::SyncError, StandardError => e
        Accounting.log('Hook', 'Sync', error: e.message)
      end
    end

    def sync!
      raise Accounting::SyncError.new('Method `sync!` not defined within the specific service class.', payload)
    end

    def delete?
      event == 'deleted'
    end

end
