require 'singleton'
require 'faraday'

module DBLChecker
  class SlackNotifier
    include Singleton

    def initialize
      @webhook_url = DBLChecker.configuration.slack_webhook_url
      @headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
    end

    def call(check)
      raise DBLChecker::Errors::ConfigError, 'Must configure a Slack webhook URL' if @webhook_url.nil?

      Faraday.post(
        @webhook_url,
        check.to_json,
        @headers,
      )
    rescue StandardError => e
      raise DBLChecker::Errors::ServerError, "Failed to notify Slack. Error: #{e.message}"
    end
  end
end
