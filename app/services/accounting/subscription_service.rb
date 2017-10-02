module Accounting
  class SubscriptionService < AccountingService

    def sync!
      if delete?
        resource.destroy!
        return
      end

      # Ensure the transaction has the associated profile and payment associated
      resource.profile_id ||= profile.id
      resource.payment_id ||= payment.id

      # If a new transaction, pre-set the job id so it doesn't get put into the ActiveJob queue when saved
      resource.job_id ||= '0'

      # Assign the attributes
      resource.assign_attributes(
        name: name,
        amount: amount,
        status: status,
        description: details.description,
        total_occurrences: details.total_occurrences,
        length: details.payment_schedule.length,
        unit: details.payment_schedule.unit,
        trial_amount: details.trial_amount,
        start_date: details.payment_schedule.start_date
      )

      resource.profile.accountable.try(:run_hook, :before_subscription_sync, resource)

      resource.save!

      resource.profile.accountable.try(:run_hook, :after_subscription_sync, resource)
    end

    def resource
      @resource ||= Accounting::Subscription.find_or_initialize_by(subscription_id: payload[:id])
    end

    def name
      payload[:name]
    end

    def amount
      payload[:amount]
    end

    def status
      payload[:status]
    end

    def profile
      if Accounting::Profile.exists?(profile_id: payload[:profile][:customer_profile_id])
        Accounting::Profile.find_by(profile_id: payload[:profile][:customer_profile_id])
      else
        raise Accounting::SyncWarning.new("Subscription cannot be created, profile with id '#{payload[:profile][:customer_profile_id]}' could not be found.", payload)
      end
    end

    def payment
      if profile.payments.exists?(payment_profile_id: payload[:profile][:customer_payment_profile_id])
        profile.payments.find_by(payment_profile_id: payload[:profile][:customer_payment_profile_id])
      else
        raise Accounting::SyncWarning.new("Subscription cannot be created because the defined payment method was not found on the accountable profile", payload)
      end
    end

    def details
      if resource.details.nil?
        raise Accounting::SyncError.new("Subscription cannot be created because the record could not be found.", payload)
      else
        resource.details
      end
    end

  end
end
