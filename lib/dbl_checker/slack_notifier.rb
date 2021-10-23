require 'singleton'
require 'farady'

module DblChecker
  class SlackNotifier
    include Singleton

    def initialize
      @webhook_url = DblChecker.configuration.slack_webhook_url
      @headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
    end

    def notify(check)
      Faraday.post(
        @webhook_url,
        check.to_json,
        @headers,
        )
    rescue StandardError => e
      raise DblChecker::ServerError, "Failed to notify Slack. Error: #{e.message}"
    end
  end
end
