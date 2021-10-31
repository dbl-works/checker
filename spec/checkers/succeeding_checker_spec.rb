require 'test_helper'

class SucceedingChecker < ActiveSupport::TestCase
  class SomeChecker
    include DBLChecker::Job

    check_options(
      name: 'some check',
      description: 'some_checker',
      aggregate_failures: true,
    )

    def perform
      assert(true, 'this should not fail')
    end
  end

  test 'aggregates failures' do
    check = SomeChecker.new.perform_check
    assert_nil(check.error)
    assert(check.execution_time_in_ms >= 0)
    assert(check.finished_at)
    assert(check.job_klass == 'SucceedingChecker::SomeChecker')
    assert(check.name == 'some check')
    assert(check.description == 'some_checker')
    assert(check.app_version == 'some-git-sha')
  end
end
