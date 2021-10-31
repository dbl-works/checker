require 'test_helper'

class FailingChecker < ActiveSupport::TestCase
  class SomeChecker
    include DBLChecker::Job

    check_options(
      name: 'some check',
    )

    def perform
      assert(false, 'this should fail')
      assert(false, 'by default, exit early')
    end
  end

  test 'fails early' do
    check = SomeChecker.new.perform_check
    assert_equal(check.error, 'this should fail')
  end
end
