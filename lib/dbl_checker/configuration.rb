#
# Global gem configuration class
#
module DblChecker
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
    attr_accessor :mock
    attr_accessor :mock_job_executions
    attr_accessor :logger

    def initialize
      @logger = nil
      @mock = false
      @mock_job_executions = {}
      @slack_webhook_url = nil
      @app_version = nil
      @default_check_options = {
        every: 24.hours, # 24 hours
        importance: :low,
        active: true,
        slack_channel: 'checkers',
        timeout_in_seconds: 30,
        aggregate_failures: false,
      }
    end
  end
end
