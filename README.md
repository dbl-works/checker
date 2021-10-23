# Dbl Checker

## Example usage
```ruby
class TransactionChecker
  include DblChecker::Job

  check_options(
    every: 4.hours.to_i,
    description: 'Check transactions exist and are zero in sum',
    name: 'transactions_checker',
    importance: :high,
    aggregate_failures: true,
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


## Deployment
Must have ENV var `DBL_CHECKER_API_KEY` to persist jobs remotely.


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
