class AccountingService

    attr_accessor :payload, :event, :api_creds

    def initialize(payload={}, event=nil, api_creds=nil)
      @payload = payload
      @event = event
      @api_creds = api_creds
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

    def hook_api_options
      return {} if api_creds.nil?
      {
        api_login: api_creds[:login],
        api_key: api_creds[:key]
      }
    end

end
