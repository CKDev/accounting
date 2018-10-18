module Accounting
  class Config

    attr_accessor :gateway, :cancel_subscription_on_destroy, :queue, :logger, :domain
    attr_writer :signatures

    def initialize
      @signatures = []
      @gateway ||= :sandbox
      @cancel_subscription_on_destroy ||= false
      @queue ||= :default
      @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(Rails.root.join('log', 'accounting.log'), 'weekly'))
      @domain ||= 'example.org'
    end

    def signatures
      if @signatures.respond_to?(:call)
        @signatures.call
      else
        @signatures
      end
    end

  end
end
