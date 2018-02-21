module Accounting
  class SubscriptionJob < ::ActiveJob::Base

    # No need to do anything
    # Duplicates are not seen as failures since according to
    # authorize.net, they have already been run
    discard_on Accounting::DuplicateError

    def perform(subscription)
      subscription.process_now! if valid_job?(subscription)
    end

    private

    def valid_job?(subscription)
      # TODO: I'm not sure the full logic here, yet.  But for now, as long as it doesn't
      # have a subscription_id, it's safe to run.
      if subscription.subscription_id.blank?
        Accounting.log 'Subsription', 'Job', { info: "Subsription: #{subscription.id} - no subscription_id, processing..." }
        true
      else
        Accounting.log 'Subsription', 'Job', { info: "Subsription: #{subscription.id} - already has subscription_id, skipping..." }
        false
      end
    end

  end
end
