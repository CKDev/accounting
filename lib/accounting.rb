require 'accounting/version'
require 'accounting/config'
require 'accounting/active_record'
require 'accounting/action_dispatch/routes'

require 'hooks'
require 'htmlentities'
require 'authorize_net'
require 'credit_card_validator'


module Accounting

  class DuplicateError < ::StandardError; end

  class SubscriptionError < ::StandardError; end

  class SubscriptionCanceledError < ::StandardError; end

  class SyncError < ::StandardError
    def initialize(message, payload={})
      @payload = payload
      super(message)
    end

    def payload
      @payload
    end
  end

  class SyncWarning < ::StandardError
    def initialize(message, payload={})
      @payload = payload
      super(message)
    end

    def payload
      @payload
    end
  end

  def self.setup
    yield config
  end

  def self.config
    @config ||= Config.new
  end

  def self.api(type, **options)
    options[:api_login] ||= config.login
    options[:api_key] ||= config.key
    case type.to_sym
      when :arb
        AuthorizeNet::ARB::Transaction.new(options[:api_login], options[:api_key], { gateway: config.gateway })
      when :cim
        AuthorizeNet::CIM::Transaction.new(options[:api_login], options[:api_key], { gateway: config.gateway })
      when :reporting
        AuthorizeNet::Reporting::Transaction.new(options[:api_login], options[:api_key], { gateway: config.gateway })
      when :api
        AuthorizeNet::API::Transaction.new(options[:api_login], options[:api_key], { gateway: config.gateway })
    end
  end

  def self.log(*tags, **messages)
    if config.logger.is_a?(ActiveSupport::TaggedLogging)
      tags.unshift(Time.now.to_s)
      config.logger.tagged(*tags) do
        messages.each { |type, message| config.logger.send(type, message) }
      end
    else
      messages.each { |type, message| config.logger.send(type, "[#{Time.now.to_s}] #{message}") }
    end
  end

  module Test
    autoload :CreateCard, 'accounting/test/create_card'
  end
  
end

require 'accounting/engine' if defined?(Rails)
