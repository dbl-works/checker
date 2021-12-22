require 'test_helper'

class Validator < ActiveSupport::TestCase
  class InvalidStrategy; end

  def valid?(strategy)
    DBLChecker::Adapters::Validator.call(strategy)
  end

  test 'detects an invalid strategy' do
    assert !valid?(InvalidStrategy)
  end

  test 'local is a valid strategy' do
    assert valid?(DBLChecker::Adapters::Persistance::Local)
  end

  test 'slack is a valid strategy' do
    assert valid?(DBLChecker::Adapters::Persistance::Slack)
  end

  test 'mock is a valid strategy' do
    assert valid?(DBLChecker::Adapters::Persistance::Mock)
  end

  test 'DBL platform is a valid strategy' do
    assert valid?(DBLChecker::Adapters::Persistance::DBLCheckerPlatform)
  end
end
