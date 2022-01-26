require 'test_helper'

class Resolver < ActiveSupport::TestCase
  class InvalidAdapter; end # rubocop:disable Lint/EmptyClass

  module ValidAdapterClass
    def self.call
    end
  end

  class ValidAdapterInstance
    def call
    end
  end

  class ValidAdapterSingleton
    require 'singleton'
    include Singleton
    def initialize
    end

    def call
    end
  end

  def instance_for(adapter)
    DBLChecker::Adapters::Resolver.call(adapter)
  end

  test 'raises an error when invalid adapter passed' do
    assert_raises(DBLChecker::Errors::ConfigError) { instance_for(InvalidAdapter) }
  end

  test 'returns instance for class, instance, and singleton adapters' do
    [ValidAdapterClass, ValidAdapterInstance, ValidAdapterSingleton].each do |adapter|
      assert instance_for(adapter).respond_to?(:call)
    end
  end

  test 'job_executions: local is correctly resolved' do
    assert instance_for(DBLChecker::Adapters::JobExecutions::Local).respond_to?(:call)
  end

  test 'job_executions: mock is correctly resolved' do
    assert instance_for(DBLChecker::Adapters::JobExecutions::Mock).respond_to?(:call)
  end

  test 'job_executions: DBL platform is correctly resolved' do
    assert instance_for(DBLChecker::Adapters::JobExecutions::DBLCheckerPlatform).respond_to?(:call)
  end
end
