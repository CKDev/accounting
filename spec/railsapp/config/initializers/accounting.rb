Accounting.setup do |config|

  # API Gatway. Should be one of: 'production' or 'sandbox'
  config.gateway = :sandbox

  # Whether or not to auto cancel subscriptions when the associated subscription record is destroyed
  # config.cancel_subscription_on_destroy = false

  # The default queue to add Transaction/Subscription/Hook background jobs to
  config.queue = :default

end
