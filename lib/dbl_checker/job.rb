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
        return unless due?(last_executed_at)

        Timeout.timeout(@check_options[:timeout_in_seconds]) do
          perform
        end

      rescue DBLChecker::AssertionFailed => e
        @errors << e.message
      rescue Timeout::Error => e
        @errors << e.message # "execution expired"
        @check.timout_after_seconds = @check_options[:timeout_in_seconds]
      ensure
        # write from @errors here, so we collect any errors logged before an exception occurred
        @check.error = @errors.join('\n')
        persist_check_on_remote
        notify_slack
      end

      private

      def due?(last_executed_at)
        return true if last_executed_at.nil? || last_executed_at.empty?

        last_executed_at < @check_options[:every].ago
      end

      def assert(success, message)
        return if success

        if @check_options[:aggregate_failures]
          @errors << message
        else
          raise DBLChecker::AssertionFailed, message
        end
      end

      def persist_check_on_remote
        DBLChecker::Remote.instance.persist(@check)
      end

      def notify_slack
        return if DBLChecker.configuration.slack_webhook_url.nil?

        DBLChecker::SlackNotifier.instance.notify(@check)
      end
    end
  end
end
