class User < ApplicationRecord
  creds = YAML.load_file(File.dirname(__FILE__) + '/../../../credentials.yml')

  accountable email: :email, id: proc { |u| SecureRandom.hex(4) }, description: 'Test Description',
    api_login: proc { creds['login'] },
    api_key: proc { creds['key'] },
    api_validation_mode: :testMode

  # Transaction Callbacks
  before_transaction_submit :before_submit_transaction

  after_transaction_submit :after_submit_transaction

  before_transaction_sync :before_sync_transaction

  after_transaction_sync :after_sync_transaction

  # Subscription Callbacks
  before_subscription_submit :before_submit_subscription

  after_subscription_submit :after_submit_subscription

  before_subscription_cancel :before_cancel_subscription

  after_subscription_cancel :after_cancel_subscription

  before_subscription_sync :before_sync_subscription

  after_subscription_sync :after_sync_subscription

  before_subscription_tick :before_tick_subscription

  after_subscription_tick :after_tick_subscription
  
  def before_submit_transaction(transaction)
    puts "before_submit_transaction #{transaction}" unless Rails.env.test?
  end

  def after_submit_transaction(transaction)
    puts "after_submit_transaction #{transaction}" unless Rails.env.test?
  end

  def before_sync_transaction(transaction)
    puts "before_sync_transaction #{transaction}" unless Rails.env.test?
  end

  def after_sync_transaction(transaction)
    puts "after_sync_transaction #{transaction}" unless Rails.env.test?
  end

  def before_submit_subscription(transaction)
    puts "before_submit_subscription #{transaction}" unless Rails.env.test?
  end

  def after_submit_subscription(transaction)
    puts "after_submit_subscription #{transaction}" unless Rails.env.test?
  end

  def before_sync_subscription(transaction)
    puts "before_sync_subscription #{transaction}" unless Rails.env.test?
  end

  def after_sync_subscription(transaction)
    puts "after_sync_subscription #{transaction}" unless Rails.env.test?
  end

  def before_tick_subscription(subscription, transaction)
    puts "before_tick_subscription #{subscription} #{transaction}" unless Rails.env.test?
  end

  def after_tick_subscription(subscription, transaction)
    puts "after_tick_subscription #{subscription} #{transaction}" unless Rails.env.test?
  end

  def before_cancel_subscription(subscription)
    puts "before_cancel_subscription #{subscription}" unless Rails.env.test?
  end

  def after_cancel_subscription(subscription)
    puts "after_cancel_subscription #{subscription}" unless Rails.env.test?
  end

end
