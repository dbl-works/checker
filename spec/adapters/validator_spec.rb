require 'test_helper'

class Validator < ActiveSupport::TestCase
  class InvalidAdapter; end

  def valid?(adapter)
    DBLChecker::Adapters::Validator.call(adapter)
  end

  test 'detects an invalid adapter' do
    assert !valid?(InvalidAdapter)
  end

  test 'local is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::Local)
  end

  test 'slack is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::Slack)
  end

  test 'mock is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::Mock)
  end

  test 'DBL platform is a valid adapter' do
    assert valid?(DBLChecker::Adapters::Persistance::DBLCheckerPlatform)
  end
end
