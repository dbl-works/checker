require 'singleton'

module DBLChecker
  module Adapters
    module JobExecutions
      class Mock
        include Singleton

        def call
          {}
        end
      end
    end
  end
end
