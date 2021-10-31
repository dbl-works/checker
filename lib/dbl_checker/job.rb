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

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def perform_check(last_executed_at = nil)
        return unless @check_options[:active]
        return unless due?(last_executed_at)

        Timeout.timeout(@check_options[:timeout_in_seconds]) do
          start = Time.current
          perform
          @check.execution_time_in_ms = ((Time.current - start) * 1_000).to_i
        end

        @check
      rescue DBLChecker::Errors::AssertionFailedError => e
        @errors << e.message
        @check
      rescue Timeout::Error => e
        @errors << e.message # "execution expired"
        @check.timout_after_seconds = @check_options[:timeout_in_seconds]
        @check
      ensure
        # write from @errors here, so we collect any errors logged before an exception occurred
        @check.error = @errors.join('\n').presence
        @check.finished_at = Time.current
        persist_check
        @check
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
        klass = DBLChecker.configuration.adapters[:persistance]
        instance = klass.ancestors.include?(Singleton) ? klass.instance : klass.new
        instance.call(@check)
      end
    end
  end
end
