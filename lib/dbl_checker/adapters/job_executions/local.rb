require 'singleton'

module DBLChecker
  module Adapters
    module JobExecutions
      class Local
        include Singleton

        def call
          ::DBLCheck
            .select('DISTINCT ON (job_klass) checks.*')
            .order('job_klass, finished_at DESC')
            .map { |check| { job_klass: check.job_klass, last_executed_at: check.finished_at } }
        end
      end
    end
  end
end
