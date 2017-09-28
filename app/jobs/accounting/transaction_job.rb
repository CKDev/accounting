module Accounting
  class TransactionJob < ::ActiveJob::Base

    rescue_from ActiveJob::DeserializationError do |exception|
      # Transaction model was destroyed, for now, fail gracefully
      # TODO: Consider notifying someone when this happens
    end

    # No need to do anything, just rescue from the error
    # Duplicates are not seen as failures since according to
    # authorize.net, they have already been run
    rescue_from ::Accounting::DuplicateError do |exception|
    end

    def perform(transaction)
      transaction.process_now!
    end

  end
end
