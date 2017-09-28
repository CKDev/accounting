module Accounting
  class TransactionService < AccountingService

    include AccountingHelper

    def sync!
      # Ensure the transaction has the associated profile and payment associated
      resource.profile_id ||= profile.id
      resource.payment_id ||= payment.id

      # If a new transaction, pre-set the job id so it doesn't get put into the ActiveJob queue when saved
      resource.job_id ||= '0'

      raise Accounting::SyncError.new("Transaction with id #{payload[:id]} not found in Authorize.NET", payload) if resource.details.nil?

      # Assign the attributes
      resource.assign_attributes(
        transaction_type: type,
        transaction_method: method,
        authorization_code: resource.details.auth_code,
        avs_response: resource.details.avs_response,
        amount: resource.details.auth_amount,
        submitted_at: resource.details.submitted_at,
        status: status
      )

      if subscription?
        resource.assign_attributes(subscription_id: subscription.id, subscription_payment: resource.details.subscription_paynum.to_i)
      end

      resource.profile.accountable.try(:run_hook, :before_subscription_tick, subscription, resource) if subscription?
      resource.profile.accountable.try(:run_hook, :before_transaction_sync, resource)

      resource.save!

      resource.profile.accountable.try(:run_hook, :after_transaction_sync, resource)
      resource.profile.accountable.try(:run_hook, :after_subscription_tick, subscription, resource) if subscription?
    end

    def resource
      @resource ||= Accounting::Transaction.find_or_initialize_by(transaction_id: payload[:id])
    end

    def type
      resource.details.type.underscore.chomp('_transaction')
    end

    def status(input=resource.details.status)
      case input
        when 'voided'; 'voided'
        when 'expired'; 'expired'
        when 'declined'; 'declined'
        when 'returnedItem'; 'returned'
        when 'authorizedPendingCapture'; 'held'
        when 'FDSPendingReview', 'FDSAuthorizedPendingReview'; 'fraud'
        when 'failedReview', 'approvedReview', 'underReview'; 'pending'
        when 'capturedPendingSettlement', 'settledSuccessfully'; 'captured'
        when 'refundSettledSuccessfully', 'refundPendingSettlement'; 'refunded'
        when 'communicationError', 'couldNotVoid', 'generalError', 'settlementError'; 'error'
        else 'pending'
      end
    end

    def method
      resource.details.payment_method.class::PAYMENT_METHOD_CODE
    end

    def card?
      resource.details.payment_method.is_a?(AuthorizeNet::CreditCard)
    end

    def ach?
      resource.details.payment_method.is_a?(AuthorizeNet::ECheck)
    end

    def last_four
      if card?
        resource.details.payment_method.card_number[-4..-1]
      elsif ach?
        resource.details.payment_method.account_number[-4..-1]
      end
    end

    def profile
      if Accounting::Profile.exists?(authnet_email: resource.details.customer.email)
        Accounting::Profile.find_by(authnet_email: resource.details.customer.email)
      else
        raise Accounting::SyncWarning.new("Transaction cannot be created, profile with email '#{resource.details.customer.email}' could not be found.", payload)
      end
    end

    def payment
      if profile.payments.exists?(last_four: last_four, profile_type: card? ? :card : :ach)
        profile.payments.find_by(last_four: last_four, profile_type: card? ? :card : :ach)
      else
        raise Accounting::SyncWarning.new("Transaction cannot be created because the defined payment method was not found on the accountable profile", payload)
      end
    end

    def subscription?
      resource.details.subscription_id.present? && resource.details.subscription_paynum.present? && subscription.present?
    end

    def subscription
      @subscription ||= Accounting::Subscription.find_by(subscription_id: resource.details.subscription_id.to_i)
    end

  end
end
