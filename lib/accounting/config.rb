module Accounting
  class Config

    attr_accessor :gateway, :cancel_subscription_on_destroy, :queue, :logger, :domain, :api_creds

    def initialize
      @api_creds = {}
      @gateway ||= :sandbox
      @cancel_subscription_on_destroy ||= false
      @queue ||= :default
      @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(Rails.root.join('log', 'accounting.log'), 'weekly'))
      @domain ||= 'example.org'
    end

    def api_creds=(api_creds)
      @api_creds = api_creds.deep_symbolize_keys
      @api_creds.stringify_keys!
    end

  end
end
