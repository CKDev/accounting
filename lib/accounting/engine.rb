module Accounting
  class Engine < Rails::Engine

    isolate_namespace Accounting

    initializer 'accounting.initialize' do
      ::ActiveRecord::Base.send :include, ::Accounting::ActiveRecord
      ::ActionDispatch::Routing::Mapper.send :include, ::Accounting::Routes
    end

  end
end
