Accounting.setup do |config|

  # API Login
  config.login = '8U46Pew5dfF'

  # API Key
  config.key = '3m26PD4kdzX4U358'

  # API Signature Key
  config.signature = '9A22045DF31C78E98C1EE7430EFB5497D327B10C40CA373E784A98EADD0EF6E0F87CB083D5C5FDE717BD1707877CAC6105125022637BBF0BC5139D009F92F777'

  # Validation Mode for Payment Profiles. Must be one of: testMode, liveMode, or none
  config.validation_mode = :testMode

  # API Gatway. Should be one of: 'production' or 'sandbox'
  config.gateway = :sandbox

  # Whether or not to auto cancel subscriptions when the associated subscription record is destroyed
  # config.cancel_subscription_on_destroy = false

  # The default queue to add Transaction/Subscription/Hook background jobs to
  config.queue = :default

end
