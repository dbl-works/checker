require 'singleton'

module DBLChecker
  module Adapters
    module Persistance
      class Mock
        include Singleton

        def call(check)
          puts "persisted check #{check.to_json}"
          check
        end
      end
    end
  end
end
