require 'test_helper'

class InactiveChecker < ActiveSupport::TestCase
  class SomeChecker
    include DBLChecker::Job

    check_options(
      active: false,
    )

    def perform
      assert(false, 'this should not run because it is inactive')
    end
  end

  test 'aggregates failures' do
    check = SomeChecker.new.perform_check
    assert_nil(check)
  end
end
