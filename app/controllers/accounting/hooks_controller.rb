module Accounting
  class HooksController < ActionController::Base

    before_action :log_debug

    def create
      enqueue_job
    end

    def update
      enqueue_job
    end

    def destroy
      enqueue_job
    end

    private

      def log_debug
        Accounting.log('Hook', action_name.titleize, debug: payload)
      end

      def enqueue_job
        Accounting::HookJob.set(queue: Accounting.config.queue || :default).new.perform(signature, body, payload, params.require(:uid))
        head :ok
      end

      def signature
        request.headers['X-Anet-Signature'].to_s.split('=').last
      end

      def payload
        params.try(:to_unsafe_h) || {}
      end

      def body
        request.body.read
      end

  end
end
