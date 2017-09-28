module Accounting
  class HooksController < ActionController::Base

    before_action :authorize_hook!

    before_action :log_debug

    rescue_from Accounting::SyncError, with: :sync_failure

    rescue_from Accounting::SyncWarning, with: :sync_failure

    def create
      hook.handle!
      head :ok
    end

    def update
      hook.handle!
      head :ok
    end

    def destroy
      hook.handle!
      head :ok
    end

    private

      def hook
        Accounting::HookService.new(params)
      end

      def log_debug
        Accounting.log('Hook', action_name.titleize, debug: params.to_unsafe_h)
      end

      def authorize_hook!
        begin
          # Because tests are dumb... http://jbilbo.com/blog/2015/05/19/testing-cors-with-rspec/
          # See first paragraph under "How to test it with RSpec"
          signature = (Rails.env.test? ? request.headers['HTTP_X_ANET_SIGNATURE'] : request.headers['X-Anet-Signature']).to_s.split('=').last
          raise if signature.blank?
          raise unless signature == OpenSSL::HMAC.hexdigest('SHA512', Accounting.config.signature, request.body.read).upcase
        rescue => e
          head :forbidden
        end
      end

      def sync_failure(exception)
        if exception.is_a?(Accounting::SyncError)
          Accounting.log('Hook', 'Error', error: "#{exception.message}\n\t\t#{exception.payload}")
          # A sync error is something that can't be recovered from, send 200 so authorize.net doesn't try again
          head :ok
        elsif exception.is_a?(Accounting::SyncWarning)
          Accounting.log('Hook', 'Warning', warn: "#{exception.message}\n\t\t#{exception.payload}")
          # Non-200 response, authorize.net will try the request again
          head :internal_server_error
        end
      end

  end
end
