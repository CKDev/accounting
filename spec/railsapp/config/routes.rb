require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :accounting do
    post    'hooks', to: 'hooks#create'
    put     'hooks', to: 'hooks#update'
    delete  'hooks', to: 'hooks#destroy'
  end

  mount Sidekiq::Web => '/sidekiq'
end
