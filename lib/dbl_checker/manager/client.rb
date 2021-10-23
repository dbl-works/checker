require 'active_support/all'
require_relative '../remote'
require_relative '../server_error'

module DblChecker
  module Manager
    # persistent process, that checks for jobs and executes them
    class Client
      # find all checker jobs in the codebase
      # check, when each job was last executed
      # if the job is due, execute it

      ITERATE_JOBS_EVERY = 1.hour.to_i

      def run
        write_pid_to_file

        loop do
          executions.each do |job_klass, last_executed_at|
            `bundle exec rails runner "#{job_klass}.new.perform_check(last_executed_at: #{last_executed_at})"`
          end

          sleep(ITERATE_JOBS_EVERY)
        end
      end

      def jobs
        @jobs ||= Dir['app/checkers/**/*_checker.rb'].map do |file_name|
          file_name[/app\/checkers\/(.*)\.rb/, 1].classify
        end
      end

      def executions
        executions_from_remote = fetch_executions_from_remote
        jobs.map do |job_klass|
          {
            job_klass: job_klass,
            last_executed_at: executions_from_remote[job_klass]&.to_time,
          }
        end
      end

      # {
      #   'FooChecker' => '2021-10-23 21:27:03 +0200',
      #   'BarChecker' => '2021-10-23 08:15:03 +0200',
      # }
      def fetch_executions_from_remote
        DblChecker::Remote.instance.job_executions
      end

      def write_pid_to_file
        File.open('tmp/pids/dbl_checker.pid', 'w') do |f|
          f.write(Process.pid)
        end
      end
    end
  end
end
