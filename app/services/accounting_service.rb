class AccountingService

  attr_accessor :payload, :event, :uid

  ##
  # @param uid Identifier for authnet account
  #
  # @author Ming <ming@commercekitchen.com>
  def initialize(payload={}, event=nil, uid=nil)
    @payload = payload
    @event = event
    @uid = uid
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
    cred = Accounting.config.api_creds(uid)
    return {} if cred.nil?

    { api_login: cred[:login], api_key: cred[:key] }
  end

end
