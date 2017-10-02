module Accounting
  class SubscriptionJob < ::ActiveJob::Base

    # Subscription model was destroyed. For now, fail gracefully
    # TODO: Consider notifying someone when this happens
    discard_on ActiveJob::DeserializationError

    # No need to do anything
    # Duplicates are not seen as failures since according to
    # authorize.net, they have already been run
    discard_on Accounting::DuplicateError

    def perform(subscription)
      subscription.process_now!
    end

  end
end
