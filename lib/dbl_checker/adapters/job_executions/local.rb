require 'singleton'

module DBLChecker
  module Adapters
    module JobExecutions
      class Local
        include Singleton

        def call
          json = `bundle exec rails runner -e "$RAILS_ENV" "puts #{command}.to_json"`.split.last

          JSON.parse(json, symbolize_names: false)
        end

        private

        def command
          [
            '::DBLCheck',
            ".select('DISTINCT ON (job_klass) dbl_checks.*')",
            ".order('job_klass, finished_at DESC')",
            '.map { |check| { check.job_klass => check.finished_at } }',
            '.inject(:merge)',
          ].join
        end
      end
    end
  end
end
