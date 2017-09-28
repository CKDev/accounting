[![Coverage Status](https://coveralls.io/repos/github/ehainer/accounting/badge.svg?branch=master)](https://coveralls.io/github/ehainer/accounting?branch=master)
[![Build Status](https://travis-ci.org/ehainer/accounting.svg?branch=master)](https://travis-ci.org/ehainer/accounting)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

# Accounting

Integration with the Authorize.NET api, providing ActiveJob backed support for creating transactions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'accounting', '~> 0.1.0'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install accounting
    
Then run the installer to create the initializer config, accounting.rb:

    $ rails g accounting:install

Within the initializer, input your Authorize.NET api login and key as well as configure the gateway and any other options that seem applicable for your intended usage.

## Usage

To start, simply add the `accountable` method to the top of any model you'd like to associate with transactions:

```ruby
class User < ApplicationRecord

  accountable
  
  # Or with optional config that will be associated with the Authorize.NET profile
  # Each config option can be a symbol referring to a method to be called, a proc/lambda, or a static value
  # By default, email will attempt to fetch the value of the `email` method, if it exists.
  # id and description are both nil if not specified
  
  accountable email: :email_method, id: proc { |user| rand() }, description: 'Static description'
  
  def email_method
    # Do something that returns the users email address
  end

end
```

While the config is not required, it is beneficial to generate unique information, as it may help you locate your profiles within Authorize.NET later on.

Once a model is considered 'accountable' it exposes all of the available transaction methods, which consist of:

* hold
* capture
* void
* charge
* refund
* subscribe

See the details of each transaction method below for details on arguments and options.

In addition to the transaction methods, each created accountable model gets an associated `profile` which is the entry point for all Authorize.NET related data (transactions, subscriptions, payment methods, etc.) The profile will also hold the Authorize.NET profile id, encrypted via the use of the [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted) gem. Note that many of the associations that exist on the profile itself exist as delegates on the accountable model, so `@accountable.profile.payments` is the same as `@accountable.payments`. The idea is to prevent ever needing to actually interact with the profile model directly, since it largely just serves as a middle man between the subject model and the actions to be taken.

<<<<<<< HEAD
## Setup

Once you've created either a sandbox or live Authorize.net account and logged in, take the following steps to configure the app and Authorize.net to work together:

1. ![](https://media.githubusercontent.com/media/ehainer/accounting/master/settings.png | width=50%)

2. ![](https://media.githubusercontent.com/media/ehainer/accounting/master/credentials.png | width=50%)

3. ![](https://media.githubusercontent.com/media/ehainer/accounting/master/details.png | width=50%)

4. ![](https://media.githubusercontent.com/media/ehainer/accounting/master/test.png | width=50%)

5. ![](https://media.githubusercontent.com/media/ehainer/accounting/master/hooks.png | width=50%)

=======
>>>>>>> 5755b3e3caf0cd70ce18b2d4ecb5a74203968961
## Payment Methods

To create a stored payment method, simply create a new record of `@accountable.payments`, where `@accountable` is any model you've called the `accountable` method on:

**Note:** An address *must* be assigned to each payment method, as in most cases it serves as the billing address associated with the transaction.

```ruby
# Card Payment Method
@accountable.payments.create!(
  profile_type: 'card',
  number: '4012888888881881',
  ccv: '123',
  month: 8,
  year: 2022,
<<<<<<< HEAD
  address_attributes: { first_name: 'John', last_name: 'Doe', street_address: '123 Fake St', city: 'Gary', state: 'ID', zip: '11111', country: 'US' }
=======
  address: Accounting::Address.new(first_name: 'John', last_name: 'Doe', street_address: '123 Fake St', city: 'Gary', state: 'ID', zip: '11111', country: 'US')
>>>>>>> 5755b3e3caf0cd70ce18b2d4ecb5a74203968961
)

# ACH/Check Payment Method
@accountable.payments.create!(
  profile_type: 'ach',
  routing: '102003154',
  account: '1234567890',
  bank_name: 'Large Conglomerate Bank, Inc',
  account_holder: 'Frank Boyd',
  account_type: 'checking', # Possible options are: [checking, savings, businessChecking]
  check_number: '1111', # Optional, the number that appears on the check itself, i.e. - 1014
  echeck_type: 'WEB', # Optional, possible options are here: https://github.com/AuthorizeNet/sdk-ruby/blob/master/lib/authorize_net/payment_methods/echeck.rb#L20-L27
<<<<<<< HEAD
  address_attributes: { first_name: 'John', last_name: 'Doe', street_address: '123 Fake St', city: 'Gary', state: 'ID', zip: '11111', country: 'US' }
=======
  address: Accounting::Address.new(first_name: 'John', last_name: 'Doe', street_address: '123 Fake St', city: 'Gary', state: 'ID', zip: '11111', country: 'US')
>>>>>>> 5755b3e3caf0cd70ce18b2d4ecb5a74203968961
)
```

Any errors during the creation of the payment method will appear as errors on the payment instance itself. Due to possible errors that could come from Authorize.NET during the creation of a payment method, creating payments is not done via ActiveJob, since errors must be present in real time.

#### Default Payment Method

So long as one or more payment methods exist for an accountable model, one will always be flagged as the default. By default the first payment method to be created will become the default. From then on, the default payment method can be changed by calling `default!` on the payment method instance. Any other payment method flagged as default will have it's flag removed so the new default can take precedence. You can fetch the default payment method at any point by using the association helper method, `@accountable.payments.default` or check if a payment method is the default by calling `default?` on the payment instance. If the default payment method is ever deleted, the first available payment method (if any left) will be flagged as the default, to ensure that there's always a default payment method.

## Transactions

All created transactions will have an associated status that can be used to filter by. Possible statuses for *transactions* and their meaning are:

| Status    | Comment                                                                                                                                                                                                                                                                                                                                                        |
|-----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| pending   | The default status for all transactions. Any transaction that exists in the ActiveJob queue and hasn't been processed yet will be pending.                                                                                                                                                                                                                     |
| duplicate | Transactions which Authorize.NET deems to be a duplicate of an existing transaction will receive this status, and will no longer attempt to be processed as it's assumed based on Authorize.NET's response that the actual transaction has already been run. You may use this status to reference, but once flagged as a duplicate it can not be re-processed. |
| held      | Transactions that are currently "holds" on a fixed amount. Holds still need to be captured by way of the `capture` method in order to receive the amount specified.                                                                                                                                                                                            |
| captured  | Transactions that are finalized and captured, meaning the money was transferred successfully. Captured applies to both holds that were later captured as well as "charges" that were captured immediately.                                                                                                                                                     |
| voided    | Any transaction that has been successfully voided.                                                                                                                                                                                                                                                                                                             |
| refunded  | Any transaction that was of the type refund. Note that refunds don't affect the original, captured transaction. They are seen as two completely separate events, not a separate step in the life of a single transaction.                                                                                                                                      |
| expired   | Applies to "holds" only. If a hold is not captured within 30 days, it becomes an expired transaction. At which point the transaction cannot be re-processed or captured. See: AUTH_ONLY at https://support.authorize.net/authkb/index?page=content&id=A510&pmv=print&impressions=false                                                                        |

All transaction methods will simply `build` the transaction. Nothing is actually enqueued until the record itself is saved. This is for validation purposes since, for example, charging a negative amount would fail anyways. If you prefer however, each transaction method has a corresponding 'bang' method which will attempt to save and enqueue immediately, but will raise validation errors if anything is not okay. So instead of

```ruby
@accountable.charge(1.00, @accountable.payments.default)
@accountable.save
```

You could just write:

```ruby
@accountable.charge!(1.00, @accountable.payments.default) rescue 'Something went wrong'
```

### Hold

A hold will place an authorization only request for the specified amount. The hold is only valid for 30 days at which point it will expire and can no longer be captured.

```ruby
@accountable.hold(amount, payment, **options) # Requires @accountable.save
@accountable.hold!(amount, payment, **options) # Raise on validation error
```

| Argument | Comment                                                                                                                                               |
|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| amount   | Decimal value, the amount to be held.                                                                                                                 |
| payment  | An instance of `Accounting::Payment`, the payment method you want to hold the amount on. Any valid instance from `@accountable.payments` should work. |
| options  | <ul><li>**address_id** Takes either a string containing the id of an address in Authorize.NET, or an `Accounting::Address` instance from which to fetch the address id from. Used as the shipping address for the payment transaction.</li><li>**split_tender_id** A split tender transaction id as a string. If the transaction is to be part of a split tender batch, this must be included.</li><li>**custom_fields** A hash of custom fields to pass along with the payment transaction.</li></ul> |

### Capture

Given a `held` transaction, will capture the amount defined or the amount associated with the provided transaction.

```ruby
@accountable.capture(transaction, amount=nil, **options) # Requires @accountable.save
@accountable.capture!(transaction, amount=nil, **options) # Raise on validation error
```

| Argument    | Comment                                                                                                                                                        |
|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| transaction | An instance of `Accounting::Transaction` with a status of `held` that you want to capture. Held transactions can be found via `@accountable.transactions.held` |
| amount      | The specific amount to capture from the held transaction. If omitted, will just use the amount from the transaction argument's instance                        |
| options     | <ul><li>**custom_fields** A hash of custom fields to pass along with the payment transaction.</li></ul> |

### Void

Given a transaction that has been captured but not yet settled (occurs every 24 hours), will void the transaction. Any transaction that does not meet the requirements necessary to be voided, will either fail to save or raise an error, depending upon which method is used.

```ruby
@accountable.void(transaction, **options) # Requires @accountable.save
@accountable.void!(transaction, **options) # Raise on validation error
```

| Argument    | Comment                                                                                     |
|-------------|---------------------------------------------------------------------------------------------|
| transaction | An instance of `Accounting::Transaction` with a status of `captured` that you want to void. |
| options     | <ul><li>**custom_fields** A hash of custom fields to pass along with the payment transaction.</li></ul> |

### Charge

Immediately authorizes and charges the given payment method with the provided amount.

```ruby
@accountable.charge(amount, payment, **options) # Requires @accountable.save
@accountable.charge!(amount, payment, **options) # Raise on validation error
```

| Argument | Comment                                                                                                                                               |
|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| amount   | Decimal value, the amount to charge the payment method                                                                                                |
| payment  | An instance of `Accounting::Payment`, the payment method you want to charge the payment method. Any valid instance from `@accountable.payments` should work. |
| options  | <ul><li>**address_id** Takes either a string containing the id of an address, or an `Accounting::Address` instance from which to fetch the address id from. Used as the shipping address for the payment transaction.</li><li>**split_tender_id** A split tender transaction id as a string. If the transaction is to be part of a split tender batch, this must be included.</li><li>**custom_fields** A hash of custom fields to pass along with the payment transaction.</li></ul> |

### Refund

Refunds the transaction amount of a captured, *settled* transaction to the payment method defined. If the transaction has not yet settled, `void` should be used instead. Refunds can only be applied to transactions that have settled within the last 120 days.

```ruby
@accountable.refund(amount, transaction, payment=nil, **options) # Requires @accountable.save
@accountable.refund!(amount, transaction, payment=nil, **options) # Raise on validation error
```

| Argument    | Comment                                                                                                                                                                                                                                                                                                                                                                                          |
|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| amount      | Decimal value, the amount to refund. Must be less than or equal to the original transaction amount.                                                                                                                                                                                                                                                                                              |
| transaction | An instance of `Accounting::Transaction` you want to refund.                                                                                                                                                                                                                                                                                                                                     |
| payment     | An instance of `Account::Payment` that the refunded amount should be credited to. If omitted, the original payment associated with the transaction will be used. It is up to the developer to ensure the presence of the payment method originally associated with the transaction on Authorize.NET before omitting this argument. If at all possible, this should always be explicitly defined. |
| options     | <ul><li>**custom_fields** A hash of custom fields to pass along with the payment transaction.</li></ul> |

## Subscriptions

Subscriptions can be thought of as recurring transactions, and functionally are created in a nearly identical way.

```ruby
@accountable.subscribe(name, amount, payment, **options) # Requires @accountable.save
@accountable.subscribe!(name, amount, payment, **options) # Raise on validation error
```

| Argument | Comment                                                                                                                                                                                                                                                                                                                                    |
|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name     | A name that describes what the subscription is for.                                                                                                                                                                                                                                                                                        |
| amount   | Decimal value, the amount to be charged each 'interval' during the subscription. If a trial amount is required it should be set within the options using `trial_amount` and `trial_occurrences`                                                                                                                                            |
| payment  | Any instance of `Accounting::Payment` associated with the accountable profile.                                                                                                                                                                                                                                                             |
| options  | <ul><li>**description** A description of the subscription, if `name` needs to be more succinct.</li><li>**unit** The unit of time used in conjunction with `total_occurrences` to define when to charge the payment method. Can be one of: `days`, `months`. If omitted, defaults to `months`</li><li>**start_date** A `Time` object specifying the initial transaction date. If omitted, defaults to `Time.now`</li><li>**total_occurrences** The total number of occurrences in the subscription. If omitted, defaults to unlimited (subscription will have to be canceled to stop)</li><li>**trial_occurrences** The number of occurrences within the total occurrences that should be charged the `trial_amount`</li><li>**trial_amount** Decimal value, the trial amount to charge for each of the trial occurrences</li><li>**invoice_number** Optional invoice number for reference purposes</li></ul> |

<<<<<<< HEAD
## WebHooks

Provided you enter the Authorize.net signature key in the configuration and have enabled webhooks within the Authorize.net dashboard (see: Setup), Authorize.net will utilize it's own [WebHooks](https://developer.authorize.net/api/reference/features/webhooks.html) to notify the application of changes/updates to four resources: Customer Profiles, Payment Profiles, Transactions, and Subscriptions.

Note that the use of WebHooks is all but required if utilizing subscription functionality due to the fact that webhooks are the only way subscription related transactions get created and the "next transaction date" gets moved forward. If webhooks are not enabled it is entirely up to the developer to calculate when a subscription transaction occurs and update the subscription instance's `next_transaction_at` column accordingly.

=======
>>>>>>> 5755b3e3caf0cd70ce18b2d4ecb5a74203968961
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ehainer/accounting. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.en.html).
