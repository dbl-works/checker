require 'test_helper'

class Validator < ActiveSupport::TestCase
  class InvalidAdapter; end

  def valid?(adapter)
    DBLChecker::Adapters::Validator.call(adapter)
  end

  test 'detects an invalid adapter' do
    assert !valid?(InvalidAdapter)
  end

  test 'persistance: local is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::Local)
  end

  test 'persistance: slack is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::Slack)
  end

  test 'persistance: mock is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::Mock)
  end

  test 'persistance: DBL platform is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::DBLCheckerPlatform)
  end

  test 'job executions: local is a valid adapter' do
    assert valid?(DBLChecker::Adapters::JobExecutions::Local)
  end

  test 'job executions: mock is a valid adapter' do
    assert valid?(DBLChecker::Adapters::JobExecutions::Mock)
  end

  test 'job executions: DBL platform is a valid adapter' do
    assert valid?(DBLChecker::Adapters::JobExecutions::DBLCheckerPlatform)
  end
end
