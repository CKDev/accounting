module Accounting
  module Routes

    def accounting_hooks
      namespace :accounting do
        post    'hooks', to: 'hooks#create', as: :create_hook
        put     'hooks', to: 'hooks#update', as: :update_hook
        delete  'hooks', to: 'hooks#destroy', as: :destroy_hook
      end
    end

  end
end
