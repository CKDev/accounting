module Accounting
  module Routes

    def accounting_hooks
      namespace :accounting do
        post    'hooks/:uid', to: 'hooks#create', as: :create_hook
        put     'hooks/:uid', to: 'hooks#update', as: :update_hook
        delete  'hooks/:uid', to: 'hooks#destroy', as: :destroy_hook
      end
    end

  end
end
