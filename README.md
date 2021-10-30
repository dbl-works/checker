# Dbl Checker

Install the gem
```ruby
gem 'dbl-checker'
```

This gem providers a generator
```shell
rails generate dbl_checker:install
```
which will create
- a model file at `app/models/dbl_check.rb`
- a migration file `db/migrate/#{migration_version}_create_dbl_checks.rb`
- a config file at `config/initializers/gem_initializers/dbl_checker.rb`


## TODOs
- remove Slack notifications from here, the server will handle this
- server: check the SLA, if the 2nd failure of a checker occurs more than SLA-days after the 1st failure, we need to escallate that more (e.g. a different Slack notification)
- server: show metrics over how often checks fail, and how fast failures get resolved
- add CLI options to the dbl-checker so it can run locally without sending checks to remote (or offer a sandbox on remote)
- add timestamps to the check: `started_at`, `finished_at` so we can measure the duration of each check
- this gem should publish check results only to 1 service, which should be configurable (with options: `local` (i.e. write to same DB as the rails app), `slack`, and `checker_platform` (dbl works backend)) -> mostly done (missing: "local")

## Example usage
Checkers are expected to live under `app/checkers/*_checker.rb`

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

```ruby
# config/initializers/inflections.rb

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'DBL'
end
```

See the following config example; all options are optional.

```ruby
# config/initializers/gem_initializers/dbl_checker.rb
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
    # other adapters: `Slack`, `Mock`, `Local`
    # the call method expectes 1 argument (e.g. of type DBLChecker::Check)
    persistance: DBLChecker::Adapters::Persistance::DBLCheckerPlatform,
    # other adapters: `Mock`, `Local`
    # the call method expects 0 arguments
    job_executions: DBLChecker::Adapters::JobExecutions::DBLCheckerPlatform,
  }
end
```

Config for tests:

```ruby
# spec/support/dbl_checker.rb

# you could also stub the adapters's "#call" method
# allow(DBLChecker::Adapters::Persistance::DBLCheckerPlatform.instance).to receive(:call)
DBLChecker.configure do |config|
  config.adapters = {
    persistance: DBLChecker::Adapters::Persistance::Mock,
    job_executions: DBLChecker::Adapters::JobExecutions::Mock,
  }
end
```

### Error Handling
All errors happening within this gem are wrapped in one of these custom error classes:
- `DBLChecker::Errors::AssertionFailedError` -> an assertion in your check failed. This is swallowed and errors are written sent to the persistance layer
- `DBLChecker::Errors::ConfigError` -> e.g. invalid or missing configuration
- `DBLChecker::Errors::ServerError` -> cannot communicate with external server (e.g. Slack)

You can also handle all errors at once, because all errors inherit from `DBLChecker::Errors::DBLCheckerError` (which inherits from `StandardError`).


## Deployment
- Must have ENV var `DBL_CHECKER_API_KEY` to persist jobs remotely
- Must have ENV var `RAILS_ENV` defined
- Optionally set `DBL_CHECKER_HEALTHZ_PORT`, defaults to `3073`
- Run `bin/dbl-checker -c path/to/config/file` to launch the client process and the `/healthz` TCP server

Run for example:
```shell
bundle exec dbl-checker -e production -c config/initializers/gem_initializers/dbl_checker

# --locally--
bundle exec dbl-checker --environment development --config "$(pwd)/config/initializers/gem_initializers/dbl_checker"
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
