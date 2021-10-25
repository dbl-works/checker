# Dbl Checker

## TODOs
- remove Slack notifications from here, the server will handle this
- server: check the SLA, if the 2nd failure of a checker occurs more than SLA-days after the 1st failure, we need to escallate that more (e.g. a different Slack notification)
- server: show metrics over how often checks fail, and how fast failures get resolved
- add CLI options to the dbl-checker so it can run locally without sending checks to remote (or offer a sandbox on remote)
- add timestamps to the check: `started_at`, `finished_at` so we can measure the duration of each check
- refactor `DBLChecker::Remote.instance.job_executions` to expect receiving an array of hashes
- remove `id` from check -> not needed after we pull out the slack notifier

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
    Transaction.where('created_at >=', 24.hours.ago)
  end

  def transactions_sum
    Transaction.sum(:amount_base_currency)
  end
end
```


### Check options
Options that can be configured per checker. You can set global defaults in the initializer as `config.default_check_options`.

- `every`: how often a checker should be run (`24.hours` by default)
- `name`: the name of the checker for statistics and notifications
- `description`: a more detailed description of the checker for statistics and notifications
- `sla`: your commitment how much time a failed checker should be resolved (`3.days` by default)
- `runbook`: this is a link to a runbook, that describes how to handle a failure of this checker
- `timout_after_seconds`: abort a checker, if it runs longer than specified (`30` by default)
- `aggregate_failures`: when set to `false` (default) the check will exit after the first failed assertion. If set to true, all assertions are run, and errors messages will be aggregated.
- `slack_channel`: defaults to `checkers`, this is the Slack channel to receive notifications for this checker.
- `active`: wether or not this check should be active at the moment (defaults to `true`)

### Configuration options
Global options.

- `app_version`: version of your app, this can be for example the current commit hash


Example config:

```ruby
# config/initializers/gem_initializers/dbl_checker.rb
DBLChecker.configure do |config|
  # this is: https://hooks.slack.com/services/XXX
  config.slack_webhook_url = Rails.application.credentials.dig(:slack, :checkers_endpoint)
  config.app_version = ENV['COMMIT_HASH']
  config.default_check_options = {
    every: 12.hours,
    sla: 7.days,
    active: Rails.env.production?,
    slack_channel: 'checkers-project_name',
    timeout_in_seconds: 30,
  }
end
```

Config for tests:

```ruby
# spec/support/dbl_checker.rb
RSpec.configure do |config|
  config.before do
    # returns nothing, persists a check to remote
    allow(DBLChecker::Remote.instance).to receive(:persist)
    # returns a hash mapping a checker name to its last execution
    # { 'TransactionChecker' => '2021-10-22 21:02:31 UTC' }
    allow(DBLChecker::Remote.instance).to receive(:job_executions)
  end
end
```


## Deployment
- Must have ENV var `DBL_CHECKER_API_KEY` to persist jobs remotely
- Must have ENV var `RAILS_ENV` defined
- Optionally set `DBL_CHECKER_HEALTHZ_PORT`, defaults to `3073`
- Run `bin/dbl-checker` to launch the client process and the `/healthz` TCP server


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
