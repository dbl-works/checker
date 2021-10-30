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
        @check_options = self.class.instance_variable_get(:'@check_options')
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

        start = Time.current
        Timeout.timeout(@check_options[:timeout_in_seconds]) do
          perform
        end
        @check.execution_time_in_ms = ((Time.current - start) * 1_000).to_i

      rescue DBLChecker::Errors::AssertionFailedError => e
        @errors << e.message
      rescue Timeout::Error => e
        @errors << e.message # "execution expired"
        @check.timout_after_seconds = @check_options[:timeout_in_seconds]
      ensure
        # write from @errors here, so we collect any errors logged before an exception occurred
        @check.error = @errors.join('\n')
        @check.finished_at = Time.current
        persist_check
      end

      private

      def due?(last_executed_at)
        return true if last_executed_at.nil? || last_executed_at.empty?

        last_executed_at.to_time < @check_options[:every].ago
      end

      def assert(success, message)
        return if success

        if @check_options[:aggregate_failures]
          @errors << message
        else
          raise DBLChecker::Errors::AssertionFailedError, message
        end
      end

      def persist_check
        klass = DBLChecker.configuration.adapters[:persistance]
        instance = klass.ancestors.include?(Singleton) ? klass.instance : klass.new
        instance.call(@check)
      end
    end
  end
end
