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
    attr_accessor :slack_webhook_url # optional
    attr_accessor :app_version # typically this is the commit hash of the current deployed code
    attr_accessor :default_check_options
    attr_accessor :logger
    attr_accessor :adapters
    attr_accessor :dbl_checker_api_key # to persist events on DBL checker platform

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
        persistance: DBLChecker::Adapters::Persistance::DBLCheckerPlatform,
        job_executions: DBLChecker::Adapters::JobExecutions::DBLCheckerPlatform,
      }
    end
  end
end
