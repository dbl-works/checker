require 'json'
require 'singleton'
require 'faraday'

module DBLChecker
  class Remote
    include Singleton

    # read DBL_CHECKER_API_KEY from ENV, so the manager can call this without booting the main app
    def initialize
      @base_url = 'https://checkers.dbl.works'
      @headers = {
        Accept: 'application/json',
        Authorization: "Bearer #{ENV['DBL_CHECKER_API_KEY']}",
        'Content-Type': 'application/json',
      }
    end

    def persist(check)
      Faraday.post(
        "#{@base_url}/webhooks",
        check.to_json,
        @headers,
      )
    rescue StandardError => e
      raise DBLChecker::ServerError, "Failed persist check. Error: #{e.message}"
    end

    def job_executions
      response = Faraday.get(
        "#{@base_url}/job-executions",
        nil,
        @headers,
      )
      return {} if response.status != 200 || body.empty?

      JSON.parse(response.body, symbolize_names: false)
    rescue StandardError => e
      raise DBLChecker::ServerError, "Failed to check for job executions. Error: #{e.message}"
    end
  end
end
