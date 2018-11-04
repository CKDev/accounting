module Accounting
  class Config

    attr_accessor :gateway, :cancel_subscription_on_destroy, :queue, :logger, :domain
    attr_writer :api_creds

    def initialize
      @api_creds = []
      @gateway ||= :sandbox
      @cancel_subscription_on_destroy ||= false
      @queue ||= :default
      @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(Rails.root.join('log', 'accounting.log'), 'weekly'))
      @domain ||= 'example.org'
    end

    # @return Array of authnet api logins hash
    def api_creds
      if @api_creds.respond_to?(:call)
        @api_creds.call
      else
        @api_creds
      end
    end

  end
end
