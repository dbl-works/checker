module DblChecker
  module Job
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end

      module ClassMethods
        def check_options(options = {})
          options.symbolize_keys!
          DblChecker.configuration.default_check_options.merge(options)
        end
      end

      module InstanceMethods
        def initialize
          @check = DblChecker::Check.new(
            version: DblChecker.configuration.version,
            name: self.class.check_options[:name],
            description: self.class.check_options[:description],
            job_klass: self.class.name,
          )
          @errors = []
        end

        def perform_check(last_executed_at: nil)
          return unless due?(last_executed_at)

          Timeout.timeout(self.class.check_options[:timeout_in_seconds]) do
            perform
          end

        rescue DblChecker::AssertionFailed => e
          @errors << e.message
        rescue Timeout::Error => e
          @errors << e.message # "execution expired"
          @check.timout_after_seconds = self.class.check_options[:timeout_in_seconds]
        ensure
          # write from @errors here, so we collect any errors logged before an exception occurred
          @check.error = @errors.join('\n')
          persist_check_on_remote
          notify_slack
        end

        private

        def due?(last_executed_at)
          return true if last_executed_at.nil?

          last_executed_at < self.class.check_options[:every].ago
        end

        def assert(success, message)
          return if success

          if self.class.check_options[:aggregate_failures]
            @errors << message
          else
            raise DblChecker::AssertionFailed, message
          end
        end

        def persist_check_on_remote
          DblChecker::Remote.instance.persist(@check)
        end

        def notify_slack
          return if DblChecker.configuration.slack_webhook_url.nil?

          DblChecker::SlackNotifier.instance.notify(@check)
        end
      end
    end
  end
end
