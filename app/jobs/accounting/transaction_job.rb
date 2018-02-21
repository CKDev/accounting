module Accounting
  class TransactionJob < ::ActiveJob::Base

    # No need to do anything
    # Duplicates are not seen as failures since according to
    # authorize.net, they have already been run
    discard_on Accounting::DuplicateError

    def perform(transaction)
      transaction.process_now! if valid_job?(transaction)
    end

    private

    def valid_job?(transaction)
      # TODO: I'm not sure the full logic here, yet.  But for now, as long as it doesn't
      # have a transaction_id, it's safe to run.
      if transaction.transaction_id.blank?
        Accounting.log 'Transaction', 'Job', { info: "Transaction: #{transaction.id} - no transaction_id, processing..." }
        true
      else
        Accounting.log 'Transaction', 'Job', { info: "Transaction: #{transaction.id} - already has transaction_id, skipping..." }
        false
      end
    end

  end
end
