module Accounting
  class ProfileService < AccountingService

    def sync!
      if resource.nil? # Don't want to process orphaned profiles
        raise Accounting::SyncWarning.new("Profile cannot be created, profile with id '#{payload[:id]}' could not be found.", payload)
      end

      if delete?
        resource.destroy!
        return
      end

      resource.assign_attributes(
        authnet_id: details.id,
        authnet_email: details.email,
        authnet_description: details.description
      )

      resource.save! if resource.changed?

      Array.wrap(payload[:payment_profiles]).each do |payment|
        service = Accounting::PaymentService.new({ id: payment[:id], customer_profile_id: payload[:id] })
        service.sync
      end

    end

    def resource
      @resource ||= Accounting::Profile.find_by(profile_id: payload[:id])
    end

    def details
      if resource.details.nil?
        raise Accounting::SyncError.new("Customer profile cannot be created because the record could not be found.", payload)
      else
        resource.details
      end
    end

  end
end
