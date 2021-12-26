#
# Global gem configuration class
#
module DBLChecker
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  # Configuration class
  class Configuration
    # rubocop:disable Layout/EmptyLinesAroundAttributeAccessor
    attr_accessor :slack_webhook_url # optional
    attr_accessor :app_version # typically this is the commit hash of the current deployed code
    attr_accessor :default_check_options
    attr_accessor :logger
    attr_accessor :adapters
    attr_accessor :dbl_checker_api_key # to persist events on DBL checker platform
    attr_accessor :environment
    # rubocop:enable Layout/EmptyLinesAroundAttributeAccessor

    def initialize
      @default_check_options = {
        every: 24.hours,
        sla: 3.days,
        active: true,
        slack_channel: 'checkers',
        timeout_in_seconds: 30,
        aggregate_failures: false,
        runbook: nil,
      }
      @adapters = {
        persistance: %i[local slack],
        job_executions: :local,
      }
      validate_adapters!
    end

    # rubocop:disable all
    def persistance_adapters
      Array.wrap(adapters[:persistance]).map do |adapter|
        case adapter
        when :local then DBLChecker::Adapters::Persistance::Local.instance
        when :slack then DBLChecker::Adapters::Persistance::Slack.instance
        when :dbl_platform then DBLChecker::Adapters::Persistance::DBLCheckerPlatform.instance
        else
          if adapter.ancestors.include?(Singleton)
            adapter.instance
          elsif adapter.respond_to?(:new) && adapter.new.methods.include?(:call)
            adapter.new
          elsif adapter.methods.include?(:call)
            adapter
          end
        end
      end
    end
    # rubocop:enable all

    def validate_adapters!
      return if Array.wrap(adapters[:persistance]).all? { |adapter| valid_adapter?(adapter) }
      return if Array.wrap(adapters[:job_executions]).all? { |adapter| valid_adapter?(adapter) }

      raise DBLChecker::Errors::ConfigError, 'Unknown or invalid adapters configured.'
    end

    def valid_adapter?(adapter)
      return true if adapter.in?(%i[local slack dbl_platform])

      DBLChecker::Adapters::Validator.call(adapter)
    end
  end
end
