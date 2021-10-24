require 'json'
require 'singleton'
require 'faraday'

module DblChecker
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
      @mock = ENV['DBL_CHECKER_MOCK_REMOTE'] == 'true'
    end

    def persist(check)
      return puts("persisted check: #{check.to_json}") if @mock

      Faraday.post(
        "#{@base_url}/webhooks",
        check.to_json,
        @headers,
      )
    rescue StandardError => e
      raise DblChecker::ServerError, "Failed persist check. Error: #{e.message}"
    end

    def job_executions
      return { 'TransactionChecker' => '2021-10-22 21:02:31 UTC' } if @mock # 1 day ago of 23rd Oct, 21:02:31 UTC

      response = Faraday.get(
        "#{@base_url}/job-executions",
        nil,
        @headers,
      )
      return {} if response.status != 200 || body.empty?

      JSON.parse(response.body, symbolize_names: false)
    rescue StandardError => e
      raise DblChecker::ServerError, "Failed to check for job executions. Error: #{e.message}"
    end
  end
end
