# Dbl Checker

## TODOs
- remove Slack notifications from here, the server will handle this
- server: check the SLA, if the 2nd failure of a checker occurs more than SLA-days after the 1st failure, we need to escallate that more (e.g. a different Slack notification)
- server: show metrics over how often checks fail, and how fast failures get resolved

## Example usage
```ruby
class TransactionChecker
  include DBLChecker::Job

  check_options(
    every: 4.hours.to_i,
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

Find all `check_options` defined in the [DBLChecker::Check](lib/dbl_checker/check.rb) class.


## Deployment
- Must have ENV var `DBL_CHECKER_API_KEY` to persist jobs remotely
- Must have ENV var `RAILS_ENV` defined
- Optionally set `DBL_CHECKER_HEALTHZ_PORT`, defaults to `3073`
- Run `bin/dbl-checker` to launch the client process and the `/healthz` TCP server
- when `RAILS_ENV` is set to `'development'`, all https requests are mocked


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
