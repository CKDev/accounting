module Accounting
  class HookJob < ::ActiveJob::Base

    rescue_from Accounting::SyncError, with: :sync_failure

    rescue_from Accounting::SyncWarning, with: :sync_failure

    attr_accessor :signature, :body, :payload, :uid

    ##
    # @param uid Identifier for authnet account
    #
    # @author Ming <ming@commercekitchen.com>
    def perform(signature, body, payload, uid)
      @signature = signature.to_s
      @body = body.to_s
      @payload = payload
      @uid = uid.to_s.downcase
      authenticate!
      hook.handle!
    end

    private

      def hook
        Accounting::HookService.new(payload, uid)
      end

      def authenticate!
        raise Accounting::SyncError.new('Invalid signature', payload) if signature.blank?

        cred = Accounting.config.api_creds[uid]
        raise Accounting::SyncError.new("Invalid uid: #{uid}", payload) if cred.nil?

        return true if signature == OpenSSL::HMAC.hexdigest('SHA512', cred[:signature], body).upcase

        raise Accounting::SyncError.new('Invalid signature', payload)
      end

      def sync_failure(exception)
        if exception.is_a?(Accounting::SyncError)
          # A sync error is something that can't be recovered from, send 200 so authorize.net doesn't try again
          Accounting.log('Hook', 'Error', error: "#{exception.message}\n\t\t#{exception.payload}")
        elsif exception.is_a?(Accounting::SyncWarning)
          # Non-200 response, authorize.net will try the request again
          Accounting.log('Hook', 'Warning', warn: "#{exception.message}\n\t\t#{exception.payload}")
          raise exception
        end
      end

  end
end
