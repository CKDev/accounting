# -*- encoding: utf-8 -*-
# stub: accounting 0.1.5.5 ruby lib

Gem::Specification.new do |s|
  s.name = "accounting".freeze
  s.version = "0.1.5.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Hainer".freeze]
  s.bindir = "exe".freeze
  s.date = "2018-10-05"
  s.email = ["eric@commercekitchen.com".freeze]
  s.files = [".byebug_history".freeze, ".gitattributes".freeze, ".gitignore".freeze, ".rspec".freeze, ".rvmrc".freeze, ".travis.yml".freeze, "CODE_OF_CONDUCT.md".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "accounting.gemspec".freeze, "app/controllers/accounting/hooks_controller.rb".freeze, "app/helpers/accounting_helper.rb".freeze, "app/jobs/accounting/hook_job.rb".freeze, "app/jobs/accounting/subscription_job.rb".freeze, "app/jobs/accounting/transaction_job.rb".freeze, "app/models/accounting/address.rb".freeze, "app/models/accounting/payment.rb".freeze, "app/models/accounting/profile.rb".freeze, "app/models/accounting/subscription.rb".freeze, "app/models/accounting/transaction.rb".freeze, "app/services/accounting/accept_service.rb".freeze, "app/services/accounting/hook_service.rb".freeze, "app/services/accounting/payment_service.rb".freeze, "app/services/accounting/profile_service.rb".freeze, "app/services/accounting/subscription_service.rb".freeze, "app/services/accounting/transaction_service.rb".freeze, "app/services/accounting_service.rb".freeze, "bin/console".freeze, "bin/setup".freeze, "credentials.png".freeze, "db/migrate/create_accounting_addresses.rb".freeze, "db/migrate/create_accounting_payments.rb".freeze, "db/migrate/create_accounting_profiles.rb".freeze, "db/migrate/create_accounting_subscriptions.rb".freeze, "db/migrate/create_accounting_transactions.rb".freeze, "details.png".freeze, "hooks.png".freeze, "lib/accounting.rb".freeze, "lib/accounting/action_dispatch/routes.rb".freeze, "lib/accounting/active_record.rb".freeze, "lib/accounting/config.rb".freeze, "lib/accounting/engine.rb".freeze, "lib/accounting/test/create_card.rb".freeze, "lib/accounting/version.rb".freeze, "lib/generators/accounting/install_generator.rb".freeze, "settings.png".freeze, "test.png".freeze]
  s.homepage = "https://www.github.com/ehainer/accounting".freeze
  s.licenses = ["GPL-3.0".freeze]
  s.rubygems_version = "2.6.14.1".freeze
  s.summary = "Authorize.NET Accounting Integration".freeze

  s.installed_by_version = "2.6.14.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>.freeze, ["~> 5"])
      s.add_runtime_dependency(%q<credit_card_validator>.freeze, ["~> 1"])
      s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 1.3.2"])
      s.add_runtime_dependency(%q<htmlentities>.freeze, ["~> 4.3"])
      s.add_runtime_dependency(%q<hooks>.freeze, ["~> 0.4.1"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.14"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 11.3"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6"])
      s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.6.1"])
      s.add_development_dependency(%q<factory_bot_rails>.freeze, ["~> 4.8"])
      s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1"])
      s.add_development_dependency(%q<sidekiq>.freeze, ["~> 4.2.10"])
      s.add_development_dependency(%q<colorize>.freeze, ["~> 0.8.1"])
      s.add_development_dependency(%q<pg>.freeze, ["~> 0.18"])
    else
      s.add_dependency(%q<rails>.freeze, ["~> 5"])
      s.add_dependency(%q<credit_card_validator>.freeze, ["~> 1"])
      s.add_dependency(%q<bigdecimal>.freeze, [">= 1.3.2"])
      s.add_dependency(%q<htmlentities>.freeze, ["~> 4.3"])
      s.add_dependency(%q<hooks>.freeze, ["~> 0.4.1"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.14"])
      s.add_dependency(%q<rake>.freeze, ["~> 11.3"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
      s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.6.1"])
      s.add_dependency(%q<factory_bot_rails>.freeze, ["~> 4.8"])
      s.add_dependency(%q<sqlite3>.freeze, ["~> 1"])
      s.add_dependency(%q<sidekiq>.freeze, ["~> 4.2.10"])
      s.add_dependency(%q<colorize>.freeze, ["~> 0.8.1"])
      s.add_dependency(%q<pg>.freeze, ["~> 0.18"])
    end
  else
    s.add_dependency(%q<rails>.freeze, ["~> 5"])
    s.add_dependency(%q<credit_card_validator>.freeze, ["~> 1"])
    s.add_dependency(%q<bigdecimal>.freeze, [">= 1.3.2"])
    s.add_dependency(%q<htmlentities>.freeze, ["~> 4.3"])
    s.add_dependency(%q<hooks>.freeze, ["~> 0.4.1"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.14"])
    s.add_dependency(%q<rake>.freeze, ["~> 11.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
    s.add_dependency(%q<rspec-rails>.freeze, ["~> 3.6.1"])
    s.add_dependency(%q<factory_bot_rails>.freeze, ["~> 4.8"])
    s.add_dependency(%q<sqlite3>.freeze, ["~> 1"])
    s.add_dependency(%q<sidekiq>.freeze, ["~> 4.2.10"])
    s.add_dependency(%q<colorize>.freeze, ["~> 0.8.1"])
    s.add_dependency(%q<pg>.freeze, ["~> 0.18"])
  end
end
