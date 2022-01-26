# DBL Checker

[![Test](https://github.com/dbl-works/checker/actions/workflows/test.yml/badge.svg)](https://github.com/dbl-works/checker/actions/workflows/test.yml)

Provides a simple to use framework to write checkers for a Rails app.
The intention is to run regular checks in production to assure for example:
- data consistency (e.g. accounting)
- external APIs are healthy
- general assumptions about the app like user's are signing up every day, or perform certain actions in the app

This will help to catch issues in production early.

This is neither a replacement for tests nor for error handling, but rather extends an app with active monitoring of functionality and data consistency.

### Some practical examples
- Assume, your sign up/log in depends on an external OAuth provider. For what ever reason, your API key for this OAuth provider expired, or you forgot to configure it in production. It might take a while for you to figure this one out (since locally and on your staging this could work as it uses different API keys, and different credentials/ENV vars). One possibility for a checker is to verify, that you had at least one successful login (or sign up) on your app in the past 24 hours, and run this checker daily. If that checker fails, you know you must investivate the login and sign up functionality. Keeping a checker more general helps you catch more errors; No sign ups could for example also be rooted in a fault outside your app, like marketing could have sent out a wrong link in the last promotional email, or your loadbalancer is misconfigured, etc.
- Assume, your app depends on an external API for any e.g. data processing or part of a user flow (e.g. to fetch currency exchange rates, book a ticket, etc.). You likely test this feature against some sandbox environment (we assume, this test is passed), and you also test it after your first production release. Sadly, in our experience, external APIs sometimes introduce breaking changes, or they go offline for a longer period, or your IP has changed and you forgot to allowlist your new IP. When your app is large enough, you cannot possibly check all those things regularly manually. Write a checker that pings said external API once a day, or once a week, or once every hour, depending on your business needs. Know you can rest assured, that you'll be notified of any fault as soon as possible.
- Assume your application handles payment in any form, and stores these in a `transactions` table. Payments depends on many working pieces, like 3DS secure, external providers, correct CORS settings, etc. You could add a checker, that checks if you got at least one transaction record every hour/day/week to catch issues with your payment system/provider as early as possible.

Find an example checker as code below.

### Runbooks
If you wish, you can write runbooks on how to handle each failed checker, and pass the URL to your runbook to the checker; this URL will then be included in the error messsge (i.e. for Slack, you can click on the failure notification and will be redirected to the correct runbook).

### Supported Ruby & Rails Versions
Tested against Rails 6 \
Tested against Ruby 2.6 - 3.0 (see .github/workflows/test.yml).

## Contribute
Contributions are welcome 🙂 \
Please check the open **Issues** (or open one if you find any!). \
Please check open [**TODOs**](TODOs.md).

Just open a PR. If you are unsure about it, open an issue first (or comment on an existing one).

## Installation

Install the gem
```ruby
gem 'dbl-checker'

# with version, pointing to github (until the gem was released to Rubygems.org)
gem 'dbl-checker', '~> 0.3', git: 'git@github.com:dbl-works/checker'
```

This gem providers a generator
```shell
rails generate dbl_checker:install
```
which will create
- a model file at `app/models/dbl_check.rb`
- a migration file `db/migrate/#{migration_version}_create_dbl_checks.rb`
- a config file at `config/initializers/dbl_checker.rb`


## Writing Checkers
Checkers are expected to live under `app/checkers/*_checker.rb`

A simple checker may look like the following:
```ruby
# app/checkers/transaction_checker.rb
class TransactionChecker
  include DBLChecker::Job

  check_options(
    every: 4.hours,
    description: 'Check transactions exist and are zero in sum',
    name: 'transactions_checker',
    sla: 1.day,
    aggregate_failures: true,
    runbook: 'notion.so/dbl/checkers/runbooks/project-name/transactions',
  )

  def perform
    # Account balance must be zero at any time, because...
    assert(transactions_sum.zero?, "Expected transactions sum to be 0, got #{transactions_sum} instead.")
    assert(transactions_past_24h.count.positive?, 'Expected transactions to exist, but no records were persisted during the past 24 hours.')
  end

  private

  def transactions_past_24h
    Transaction.where('created_at >= ?', 24.hours.ago)
  end

  def transactions_sum
    Transaction.sum(:amount_base_currency)
  end
end
```


### Configuration
Options that can be configured per checker. You can set global defaults in the initializer as `config.default_check_options`.

When using Rais, ensure to inflect on `DBL`for this to work with Rails' autoloader/Zeitwerk.
```ruby
# config/initializers/inflections.rb

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'DBL'
end
```

See the following config example; all options are optional.

```ruby
# config/initializers/dbl_checker.rb
DBLChecker.configure do |config|
  # @NOTE: for now, we cannot load Rails here due to the way we load the config in the dbl-checker process (outside Rails)
  # config.slack_webhook_url = Rails.application.credentials.dig(:slack, :checkers_endpoint) # e.g. https://hooks.slack.com/services/XXX
  config.slack_webhook_url = ENV['CHECKERS_SLACK_WEBHOOK_ENDPOINT'] # e.g. https://hooks.slack.com/services/XXX
  config.app_version = ENV['COMMIT_HASH'] # let's you pin-point each checker-execution to a certain version of your app

  config.dbl_checker_api_key = 'some-token' # API key for the DBLCheckerPlatform adapter

  config.default_check_options = {
    every: 24.hours,           # how often a check is performed
    sla: 3.days,               # your commitment to resolve failed checks. Purely cosmetics
    active: true,              # e.g. set this to false outside production to not perform checks
    slack_channel: 'checkers', # must set the persistence adapter to "Slack" (DBLCheckerPlatform can also publish to Slack)
    timeout_in_seconds: 30,    # If a checker hasn't finished after the given time, it is killed. This check counts as failed
    aggregate_failures: false, # exit checker after the first assertion fails. Set to true to aggregate all failures
    runbook: nil,              # which runbook shall be displayed on failure that helps engineers resolve the issue
  }

  # an adapter class is expected to either be a singleton or a regular class
  # internally, this gem will attempt to call ".instance" or ".new" on the class
  # then the method `.call` is executed.
  # The "Local" resolves require a `DBLCheck` model to exist, that inherites from ActiveRecord.
  # Use the install script to scaffold a migration file.
  config.adapters = {
    # other adapters: `:slack`, `:mock`, `:local`
    # either pass a symbol for build-in adapters, or a class/module; anything that has a #call/.call method, you can also use a Singelton
    # :slack will only send messages if the check fails
    persistance: %i[slack local],
    # other adapters: `Mock`, `Local`
    # the call method expects 0 arguments
    job_executions: :local,
  }
end
```

### Config for tests

```ruby
# spec/support/dbl_checker.rb

# you could also stub the adapters's "#call" method
# allow(DBLChecker::Adapters::Persistance::Local.instance).to receive(:call)
DBLChecker.configure do |config|
  config.adapters = {
    persistance: :mock,
    job_executions: :mock,
  }
end
```

### Slack notifications
To understand the structure of the used template, a simple example [Slack template](slack_template.json) is provided. You may configure your own own one using the [Slack Kite Builder](https://app.slack.com/block-kit-builder/T9PAX51DM#%7B%22blocks%22:%5B%7B%22type%22:%22header%22,%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22:octagonal_sign:%20Checker%20Failed!%20$ENV_job_klass%22,%22emoji%22:true%7D%7D,%7B%22type%22:%22divider%22%7D,%7B%22type%22:%22section%22,%22fields%22:%5B%7B%22type%22:%22mrkdwn%22,%22text%22:%22*error*:%5Cn%20$DBL_CHECK_error%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*app%20version*:%5Cn%20$DBL_CHECK_app_version%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*timeout%20after%20seconds*:%5Cn%20$DBL_CHECK_timeout_after_seconds%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*execution%20time%20in%20ms*:%5Cn%20$DBL_CHECK_execution_time_in_ms%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*name*:%5Cn%20$DBL_CHECK_name%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*description*:%5Cn%20$DBL_CHECK_description%22%7D,%7B%22type%22:%22mrkdwn%22,%22text%22:%22*finished%20at*:%5Cn%20$DBL_CHECK_finished_at%22%7D%5D%7D,%7B%22type%22:%22section%22,%22text%22:%7B%22type%22:%22mrkdwn%22,%22text%22:%22Check%20the%20following%20runbook%20on%20how%20to%20handle%20this%20failure:%22%7D,%22accessory%22:%7B%22type%22:%22button%22,%22text%22:%7B%22type%22:%22plain_text%22,%22text%22:%22Runbook%22%7D,%22value%22:%22click_me_123%22,%22url%22:%22https://google.com%22,%22action_id%22:%22button-action%22%7D%7D%5D%7D) (this link leads you to the Kite Builder with the default template of this gem prefilled in case you want some boilerplate to start).

If you want to use a custom Slack template, overwrite the existing [Slack-Adapter](lib/dbl_checker/adapters/persistance/slack.rb) accordingly.

### Custom Adapters
You can pass any class/model that in one way or another implements a `call` methods.
This gem will figure out, wether to instantiate your passed object (e.g. by calling `.new` or `.instance` on it), or if you passed a class/module that exposes a `.call` class-method.

**Persistance**: The `call` method expects one argument that is an instance of a `Check` class. The aim is to persist this in some form (e.g. by sending it to Slack, another API, or an internal database). By default, this will send a notification to slack and persist a record in your local database.

**JobExecutions**: The `call` method expects no arguments. It returns an array of checker-class names mapped to their last execution time. The checker service uses this to determin which checkers have to run (remember, each checker can define how often it has to be execute). By default, this queries your local database.

### Error Handling
All errors happening within this gem are wrapped in one of these custom error classes:
- `DBLChecker::Errors::AssertionFailedError` -> an assertion in your check failed. This is swallowed and errors are written sent to the persistance layer
- `DBLChecker::Errors::ConfigError` -> e.g. invalid or missing configuration
- `DBLChecker::Errors::ServerError` -> cannot communicate with external server (e.g. Slack)

You can also handle all errors at once, because all errors inherit from `DBLChecker::Errors::DBLCheckerError` (which inherits from `StandardError`).


## Deployment
- must set ENV var `RAILS_ENV`
- Run `bin/dbl-checker -c path/to/config/file` to launch the client process and the `/healthz` TCP server
- [optional]] ENV var `DBL_CHECKER_API_KEY` to persist jobs remotely
- [optional] set `DBL_CHECKER_HEALTHZ_PORT`, defaults to `3000`

Run for example:
```shell
bundle exec dbl-checker -e production -c config/initializers/dbl_checker

# --locally--
bundle exec dbl-checker --environment development --config "$(pwd)/config/initializers/dbl_checker"
```

You can check the current version:
```shell
bundle exec dbl-checker -v
# --OR--
bundle exec dbl-checker --version
```


## Local testing
build the latest version of the gem locally with

```shell
gem build dbl-checker.gemspec
```
take note of the most current version of the gem, which will be printed to console.

You can use that in your Gemfile passing a local path:
```ruby
gem 'dbl-checker', path: '~/Sites/dbl-works/checker'
```
