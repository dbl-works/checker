module DBLChecker
  module Job
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def check_options(options = {})
        options.symbolize_keys!
        @check_options = DBLChecker.configuration.default_check_options.merge(options)
      end
    end

    module InstanceMethods
      def initialize
        @check_options = self.class.instance_variable_get(:@check_options)
        @check = DBLChecker::Check.new(
          app_version: DBLChecker.configuration.app_version,
          name: @check_options[:name],
          description: @check_options[:description],
          job_klass: self.class.name,
        )
        @errors = []
      end

      def perform_check(last_executed_at = nil)
        return unless @check_options[:active]
        return unless due?(last_executed_at)

        @start_time = Time.current

        Timeout.timeout(@check_options[:timeout_in_seconds]) do
          perform
        end

        finish
      rescue DBLChecker::Errors::AssertionFailedError => e
        @errors << e.message
        finish
      rescue Timeout::Error => e
        @errors << e.message # "execution expired"
        @check.timout_after_seconds = @check_options[:timeout_in_seconds]
        finish
        # don't use `ensure` here to DRY out "finish", because "ensure" will run,
        # even if we return early from one of the guard clauses
      end

      private

      def due?(last_executed_at)
        return true if last_executed_at.blank?

        last_executed_at.to_time < @check_options[:every].ago
      end

      def assert(success, message)
        return if success
        raise DBLChecker::Errors::AssertionFailedError, message unless @check_options[:aggregate_failures]

        @errors << message
      end

      def persist_check
        DBLChecker.configuration.persistance_adapters.each do |adapter|
          adapter.call(@check)
        end
      end

      def finish
        # write from @errors here, so we collect any errors logged before an exception occurred
        # same for the execution time, we want to also measure it, if we resuced an error during perfom
        @check.execution_time_in_ms = ((Time.current - @start_time) * 1_000).to_i
        @check.error = @errors.join('\n').presence
        @check.finished_at = Time.current
        persist_check
        @check
      end
    end
  end
end
