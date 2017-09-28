module Accounting
  class ProfileService < AccountingService

    def sync!
      if delete?
        resource.destroy!
        return
      end

      raise Accounting::SyncError.new("Customer profile with id #{payload[:id]} not found in Authorize.NET", payload) if resource.details.nil?

      resource.assign_attributes(
        authnet_id: resource.details.id,
        authnet_email: resource.details.email,
        authnet_description: resource.details.description
      )

      resource.save!

      Array.wrap(payload[:payment_profiles]).each do |payment|
        service = Accounting::PaymentService.new({ id: payment[:id], customer_profile_id: payload[:id] })
        service.sync
      end

    end

    def resource
      @resource ||= Accounting::Profile.find_or_initialize_by(profile_id: payload[:id])
    end

  end
end
