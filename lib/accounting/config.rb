module Accounting
  class Config

    attr_accessor :login, :key, :signature, :validation_mode, :gateway, :cancel_subscription_on_destroy, :logger

    def initialize
      @gateway ||= :sandbox
      @validation_mode ||= :none
      @cancel_subscription_on_destroy ||= false
      @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(Rails.root.join('log', 'accounting.log'), 'weekly'))
    end

  end
end