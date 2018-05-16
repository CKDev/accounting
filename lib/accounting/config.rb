module Accounting
  class Config

    attr_accessor :login, :key, :signature, :client_key, :validation_mode, :gateway, :cancel_subscription_on_destroy, :queue, :logger, :domain

    def initialize
      @gateway ||= :sandbox
      @validation_mode ||= :none
      @cancel_subscription_on_destroy ||= false
      @queue ||= :default
      @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(Rails.root.join('log', 'accounting.log'), 'weekly'))
      @domain ||= 'example.org'
    end

  end
end
