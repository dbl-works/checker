require 'singleton'

module DBLChecker
  module Adapters
    module Persistance
      class Local
        include Singleton

        def call(check)
          ::DBLCheck.create!(check.to_h)
        end
      end
    end
  end
end
