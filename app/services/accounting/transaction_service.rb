module Accounting
  class TransactionService < AccountingService

    def sync!
      # Ignore verification transactions
      return if details&.order&.description == 'Test transaction for ValidateCustomerPaymentProfile.'

      # Ensure the transaction has the associated profile and payment associated
      resource.profile_id ||= profile.id
      resource.payment_id ||= payment.id

      # If a new transaction, pre-set the job id so it doesn't get put into the ActiveJob queue when saved
      resource.job_id ||= '0'

      # Assign the attributes
      resource.assign_attributes(
        transaction_type: type,
        transaction_method: method,
        authorization_code: details.authCode,
        avs_response: details.AVSResponse,
        amount: details.authAmount,
        submitted_at: details.submitTimeUTC,
        status: status
      )

      if subscription?
        resource.assign_attributes(subscription_id: subscription.id, subscription_payment: details.subscription.payNum.to_i)
      end

      resource.profile.accountable.try(:run_hook, :before_subscription_tick, subscription, resource) if subscription?
      resource.profile.accountable.try(:run_hook, :before_transaction_sync, resource)

      resource.save!

      resource.profile.accountable.try(:run_hook, :after_transaction_sync, resource)
      resource.profile.accountable.try(:run_hook, :after_subscription_tick, subscription, resource) if subscription?
    end

    def resource
      # where().first is used here to make sure we get the first Accounting::Transaction
      # according to resource ID every time
      @resource ||= Accounting::Transaction.find_or_initialize_by(transaction_id: payload[:id])
    end

    def type
      details.transactionType.underscore.chomp('_transaction')
    end

    def status(input=details.transactionStatus)
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
      card? ? 'CC' : 'ECHECK'
    end

    def card?
      details.payment.creditCard.present?
    end

    def ach?
      details.payment.bankAccount.present?
    end

    def last_four
      if card?
        details.payment.creditCard.cardNumber[-4..-1]
      elsif ach?
        details.payment.bankAccount.accountNumber[-4..-1]
      end
    end

    def profile
      if Accounting::Profile.exists?(authnet_id: details.customer.id)
        Accounting::Profile.find_by(authnet_id: details.customer.id)
      else
        raise Accounting::SyncWarning.new("Transaction cannot be created, profile with authnet_id '#{details.customer.id}' could not be found.", payload)
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
      details.subscription.present? && subscription.present?
    end

    def subscription
      @subscription ||= Accounting::Subscription.find_by(subscription_id: details.subscription.id.to_i)
    end

    def details
      if resource.details(hook_api_options).nil?
        raise Accounting::SyncError.new("Transaction cannot be created because the record could not be found.", payload)
      end

      resource.details
    end

  end
end
