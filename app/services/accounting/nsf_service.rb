module Accounting
  class NSFService
    include AuthorizeNet::API
    include AccountingHelper

    attr_accessor :authnet_options, :start_time, :end_time

    def initialize(authnet_options, start_time, end_time)
      raise ArgumentError, 'Start and End time can\'t be blank' if start_time.nil? || end_time.nil?
      @authnet_options = authnet_options
      @start_time = start_time
      @end_time = end_time
    end

    def run(&block)
      count = 0
      echeck_batch_list.each do |batch|
        # Check Statistics array for returned items
        next unless batch.statistics.map(&:chargeReturnedItemsCount).map(&:to_i).inject(&:+).positive?
        batch_returned_transaction_ids(batch.batchId).each do |return_trans_id|
          set_nsf(find_original_transaction(return_trans_id), &block)
          count += 1
        end
      end
      Accounting.log('NSF', info: "Found total of #{count} NSF transactions")
      count
    end

    private

      def echeck_batch_list
        request = GetSettledBatchListRequest.new
        request.firstSettlementDate = start_time
        request.lastSettlementDate = end_time
        request.includeStatistics = true
      
        response = Accounting.api(:api, authnet_options).get_settled_batch_list(request)

        unless valid_authnet_response?(response) && response.messages.resultCode == MessageTypeEnum::Ok
          raise Accounting::SyncWarning.new("Failed to fetch settled batch list: #{response.messages.messages[0].text}")
        end

        if response.batchList&.batch.blank?
          Accounting.log('NSF', info: 'No settled batch list')
          return []
        end
        
        response.batchList.batch.select { |e| e.paymentMethod == 'eCheck' }
      end

      def batch_returned_transaction_ids(batch_id)
        request = AuthorizeNet::API::GetTransactionListRequest.new
        request.batchId = batch_id

        response = Accounting.api(:api, authnet_options).get_transaction_list(request)

        if response == nil || response.messages.resultCode != MessageTypeEnum::Ok || response.transactions == nil
          raise Accounting::SyncWarning.new("Failed to fetch batch transaction list: #{response.messages.messages[0].text}")
        end

        returned_transactions = response.transactions.transaction.select { |e| e.transactionStatus == 'returnedItem' }
        returned_transactions.map(&:transId)
      end

      def find_original_transaction(return_trans_id)
        details = get_transaction_details(return_trans_id)
        # refTransId is present in prod env as of May 10th, 2019
        return details.refTransId if details.refTransId.present?

        # if refTransId is missing, callback to check all transactions
        profile = Accounting::Profile.where(authnet_id: details.customer.id).last

        last_four = details.payment.bankAccount.accountNumber[-4..-1]
        payment = profile.payments.find_by!(last_four: last_four, profile_type: :ach)

        get_returned_transaction_list_for_customer(profile.profile_id, payment.payment_profile_id).each do |ot|
          get_transaction_details(ot.transId).returnedItems.returnedItem.each do |returnedItem|
            return ot.transId if returnedItem.id == return_trans_id
          end
        end
        raise Accounting::SyncWarning.new("Could not find original transaction for returned transaction #{return_trans_id}")
      end

      def get_transaction_details(trans_id)
        request = GetTransactionDetailsRequest.new
        request.transId = trans_id
        response = Accounting.api(:api, authnet_options).get_transaction_details(request)

        if response.messages.resultCode != MessageTypeEnum::Ok
          raise Accounting::SyncWarning.new("Failed to get transaction details: #{response.messages.messages[0].text}")
        end

        response.transaction
      end

      def get_returned_transaction_list_for_customer(profile_id, payment_id)
        request = AuthorizeNet::API::GetTransactionListForCustomerRequest.new
        request.customerProfileId = profile_id
        request.customerPaymentProfileId = payment_id
        request.paging = Paging.new
        request.paging.limit = 20
        request.paging.offset = 1

        request.sorting = TransactionListSorting.new
        request.sorting.orderBy = 'id'
        request.sorting.orderDescending = true

        response = Accounting.api(:api, authnet_options).get_transaction_list_for_customer(request)

        if response.messages.resultCode != MessageTypeEnum::Ok || response.transactions.nil?
          raise Accounting::SyncWarning.new("Failed to fetch transaction list for customer: #{response.messages.messages[0].text}")
        end

        response.transactions.transaction.select { |e| e.hasReturnedItems === 'true'}
      end

      def set_nsf(trans_id)
        transaction = Accounting::Transaction.find_by(transaction_id: trans_id)
        if transaction.present?
          transaction.update_column(:status, :returned)
          yield transaction if block_given?
          Accounting.log('NSF', info: "Found NSF transaction: #{trans_id}")
        else
          Accounting.log('NSF', error: "Found returned transaction #{trans_id} but it's not in RL")
        end
      end
  end
end
