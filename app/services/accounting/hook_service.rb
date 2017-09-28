module Accounting
  class HookService

    attr_accessor :hook, :payload, :event

    def initialize(hook)
      @hook = hook.to_unsafe_h.deep_transform_keys { |k| k.underscore.to_sym }
      @payload = @hook[:payload]
      @event = @hook[:event_type].split('.').last
    end

    def handle!
      service.sync! if has_service?
    end

    def has_service?
      ['transaction', 'subscription', 'customerProfile', 'customerPaymentProfile'].include?(payload[:entity_name])
    end

    def service
      case payload[:entity_name]
        when 'transaction'
          Accounting::TransactionService.new(payload, event)
        when 'subscription'
          Accounting::SubscriptionService.new(payload, event)
        when 'customerProfile'
          Accounting::ProfileService.new(payload, event)
        when 'customerPaymentProfile'
          Accounting::PaymentService.new(payload, event)
      end
    end

    def entity_name
      payload[:entity_name].try(:titleize) || 'Unknown'
    end

  end
end
