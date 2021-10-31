require 'test_helper'

class FailingWithManyChecker < ActiveSupport::TestCase
  class SomeChecker
    include DBLChecker::Job

    check_options(
      name: 'some check',
      aggregate_failures: true,
    )

    def perform
      assert(false, 'this should fail')
      assert(true, 'this should not fail')
      assert(false, 'by default, exit early')
    end
  end

  test 'aggregates failures' do
    check = SomeChecker.new.perform_check
    assert_equal(check.error, ['this should fail', 'by default, exit early'].join('\n'))
  end
end
