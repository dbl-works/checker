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
    # rubocop:disable Style/AccessorGrouping, Layout/EmptyLinesAroundAttributeAccessor
    attr_accessor :slack_webhook_url # optional
    attr_accessor :app_version # typically this is the commit hash of the current deployed code
    attr_accessor :default_check_options
    attr_accessor :logger
    attr_accessor :adapters
    attr_accessor :dbl_checker_api_key # to persist events on DBL checker platform
    # rubocop:enable Style/AccessorGrouping, Layout/EmptyLinesAroundAttributeAccessor

    # rubocop:disable Metrics/MethodLength
    def initialize
      @logger = nil
      @slack_webhook_url = nil
      @dbl_checker_api_key = nil
      @app_version = nil
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
      validate_strategies!
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable all
    def persistance
      Array.wrap(adapters[:persistance]).map do |strategy|
        case strategy
        when :local then DBLChecker::Adapters::Persistance::Local.instance
        when :slack then DBLChecker::Adapters::Persistance::Slack.instance
        when :dbl_platform then DBLChecker::Adapters::Persistance::DBLCheckerPlatform.instance
        else
          if strategy.ancestors.include?(Singleton)
            strategy.instance
          elsif strategy.respond_to?(:new) && strategy.new.methods.include?(:call)
            strategy.new
          elsif strategy.methods.include?(:call)
            strategy
          end
        end
      end
    end
    # rubocop:enable all

    def validate_strategies!
      return if Array.wrap(adapters[:persistance]).all? { |strategy| valid_strategy?(strategy) }

      raise DBLChecker::Errors::ConfigError, 'Unknown or invalid persistance strategies given.'
    end

    def valid_strategy?(strategy)
      return true if strategy.in?(%i[local slack dbl_platform])

      DBLChecker::Adapters::Validator.call(strategy)
    end
  end
end
