module Accounting
  module Generators
    class InstallGenerator < Rails::Generators::Base

      source_root File.expand_path('../../../../', __FILE__)

      desc 'Install Accounting'

      def copy_initializer
        create_file Rails.root.join('config', 'initializers', 'accounting.rb'), <<-CONTENT
Accounting.setup do |config|

  # API Login
  config.login = ''

  # API Key
  config.key = ''

  # API Signature Key
  config.signature = ''

  # API Gatway. Should be one of: 'production' or 'sandbox'
  config.gateway = :sandbox

  # Whether or not to auto cancel subscriptions when the associated subscription record is destroyed
  # config.cancel_subscription_on_destroy = false

end
CONTENT
      end

      def copy_migrations
        copy_migration 'create_accounting_addresses'
        copy_migration 'create_accounting_payments'
        copy_migration 'create_accounting_profiles'
        copy_migration 'create_accounting_subscriptions'
        copy_migration 'create_accounting_transactions'
      end

      protected

        def copy_migration(filename)
          if migration_exists?(Rails.root.join('db', 'migrate'), filename)
            say_status('skipped', "Migration #{filename}.rb already exists")
          else
            copy_file "db/migrate/#{filename}.rb", Rails.root.join('db', 'migrate', "#{migration_number}_#{filename}.rb")
          end
        end

        def migration_exists?(dirname, filename)
          Dir.glob("#{dirname}/[0-9]*_*.rb").grep(/\d+_#{filename}.rb$/).first
        end

        def migration_id_exists?(dirname, id)
          Dir.glob("#{dirname}/#{id}*").length > 0
        end

        def migration_number
          @migration_number ||= Time.now.strftime("%Y%m%d%H%M%S").to_i

          while migration_id_exists?(Rails.root.join('db', 'migrate'), @migration_number) do
            @migration_number += 1
          end

          @migration_number
        end

    end
  end
end
