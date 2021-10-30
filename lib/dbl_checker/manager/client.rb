require 'active_support/all'

module DBLChecker
  module Manager
    # persistent process, that checks for jobs and executes them
    class Client
      # find all checker jobs in the codebase
      # check, when each job was last executed
      # if the job is due, execute it

      ITERATE_JOBS_EVERY = 1.hour.to_i

      def run
        puts "Running DBLChecker::Manager::Client in #{ENV['RAILS_ENV']} mode.."

        loop do
          executions.each do |execution|
            puts "Job #{execution[:job_klass]} was last executed at #{execution[:last_executed_at]}"
            puts `bundle exec rails runner -e "$RAILS_ENV" "#{execution[:job_klass]}.new.perform_check(#{execution[:last_executed_at]})"`
          end

          sleep(ITERATE_JOBS_EVERY)
        end
      end

      # `jobs` is a method defined on IRB, hence avoid it
      def checker_jobs
        @checker_jobs ||= Dir['app/checkers/**/*_checker.rb'].map do |file_name|
          file_name[/app\/checkers\/(.*)\.rb/, 1].classify
        end
      end

      def executions
        fetched_executions = fetch_executions
        checker_jobs.map do |job_klass|
          {
            job_klass: job_klass,
            last_executed_at: fetched_executions[job_klass]&.to_time,
          }
        end
      end

      # {
      #   'FooChecker' => '2021-10-23 21:27:03 +0200',
      #   'BarChecker' => '2021-10-23 08:15:03 +0200',
      # }
      def fetch_executions
        klass = DBLChecker.configuration.adapters[:job_executions]
        instance = klass.ancestors.include?(Singleton) ? klass.instance : klass.new
        instance.call
      end
    end
  end
end
