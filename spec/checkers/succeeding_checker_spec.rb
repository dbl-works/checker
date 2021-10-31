require 'test_helper'

class SucceedingChecker < ActiveSupport::TestCase
  class SomeChecker
    include DBLChecker::Job

    check_options(
      name: 'some check',
      aggregate_failures: true,
    )

    def perform
      assert(true, 'this should not fail')
    end
  end

  test 'aggregates failures' do
    check = SomeChecker.new.perform_check
    assert_nil(check.error)
  end
end
