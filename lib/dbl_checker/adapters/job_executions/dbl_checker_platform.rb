require 'json'
require 'singleton'
require 'faraday'

module DBLChecker
  module Adapters
    module JobExecutions
      class DBLCheckerPlatform
        include Singleton

        def initialize
          @base_url = 'https://checkers.dbl.works'
          @headers = {
            Accept: 'application/json',
            Authorization: "Bearer #{DBLChecker.configuration.dbl_checker_api_key}",
            'Content-Type': 'application/json',
          }
        end

        # {
        #   'FooChecker' => '2021-10-23 21:27:03 +0200',
        #   'BarChecker' => '2021-10-23 08:15:03 +0200',
        # }
        def call
          response = Faraday.get(
            "#{@base_url}/checks/meta",
            nil,
            @headers,
          )
          return {} if response.status != 200 || body.empty?

          JSON.parse(response.body, symbolize_names: false)
        rescue StandardError => e
          raise DBLChecker::Errors::ServerError, "Failed to check for job executions. Error: #{e.message}"
        end
      end
    end
  end
end
