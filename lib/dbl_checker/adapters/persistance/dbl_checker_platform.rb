require 'json'
require 'singleton'
require 'faraday'

module DBLChecker
  module Adapters
    module Persistance
      class DBLCheckerPlatform
        include Singleton

        # read DBL_CHECKER_API_KEY from ENV, so the manager can call this without booting the main app
        # -> load config file instead
        def initialize
          @base_url = 'https://checkers.dbl.works'
          @headers = {
            Accept: 'application/json',
            Authorization: "Bearer #{ENV['DBL_CHECKER_API_KEY']}",
            'Content-Type': 'application/json',
            'X-Environment': DBLChecker.configuration.environment.to_s
          }
        end

        def call(check)
          Faraday.post(
            "#{@base_url}/webhooks",
            check.to_json,
            @headers,
          )
        rescue StandardError => e
          raise DBLChecker::Errors::ServerError, "Failed persist check. Error: #{e.message}"
        end
      end
    end
  end
end
