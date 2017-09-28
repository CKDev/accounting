module Accounting
  class SubscriptionJob < ::ActiveJob::Base

    rescue_from ActiveJob::DeserializationError do |exception|
      # Subscription model was destroyed. For now, fail gracefully
      # TODO: Consider notifying someone when this happens
    end

    # No need to do anything, just rescue from the error
    # Duplicates are not seen as failures since according to
    # authorize.net, they have already been run
    rescue_from ::Accounting::DuplicateError do |exception|
    end

    def perform(subscription)
      subscription.process_now!
    end

  end
end
