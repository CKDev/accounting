module Accounting
  class Config

    attr_accessor :gateway, :cancel_subscription_on_destroy, :queue, :logger, :domain, :api_creds

    def initialize
      @api_creds = {}
      @gateway ||= :sandbox
      @cancel_subscription_on_destroy ||= false
      @queue ||= :default
      @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(Rails.root.join('log', 'accounting.log')))
      @domain ||= 'example.org'
    end

    def api_creds=(api_creds)
      raise ArgumentError, 'Authnet API creds should be Proc or Hash' unless @api_creds.respond_to?(:call) || @api_creds.is_a?(Hash)
      @api_creds = api_creds
    end

    def api_creds(uid)
      hash = if @api_creds.respond_to?(:call)
        @api_creds.call(uid)
      elsif @api_creds.is_a?(Hash)
        @api_creds.stringify_keys[uid]
      end

      hash.deep_symbolize_keys
    end

  end
end
