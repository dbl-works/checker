require 'singleton'

module DBLChecker
  module Adapters
    module Persistance
      class Local
        include Singleton

        def call(check)
          data = check.to_h
          # our DB should take care of the ID
          # we just have it when using e.g. webhooks so we don't
          # process the same hook multiple times.
          data.delete(:id)
          ::DBLCheck.create!(data)
        end
      end
    end
  end
end
