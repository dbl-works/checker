require 'rails/generators/base'
require 'rails/active_record'
require 'active_support/core_ext/string'

module DBLChecker
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Creates a migration and a config file.'

      def create_config_file
        create_file(migration_file_path, migration_file_content)
        create_file(config_file_path, config_file_content)
      end

      private

      def config_file_path
        'config/initializers/gem_initializers/dbl_checker.rb'
      end

      def migration_file_path
        'db/migrate/20211024204809_create_dbl_checks.rb '
      end

      def config_file_content
        <<~HEREDOC
          DBLChecker.configure do |config|
            # config.slack_webhook_url = ENV['slack-mock'] # e.g. https://hooks.slack.com/services/XXX
            config.app_version = ENV['COMMIT_SHA'] # let's you pin-point each checker-execution to a certain version of your app

            # config.dbl_checker_api_key = 'some-token' # API key for the DBLCheckerPlatform adapter

            config.default_check_options = {
              # every: 24.hours,           # how often a check is performed
              # sla: 3.days,               # your commitment to resolve failed checks. Purely cosmetics
              # active: true,              # e.g. set this to false outside production to not perform checks
              # slack_channel: 'checkers', # must set the persistence adapter to "Slack" (DBLCheckerPlatform can also publish to Slack)
              # timeout_in_seconds: 30,    # If a checker hasn't finished after the given time, it is killed. This check counts as failed
              # aggregate_failures: false, # exit checker after the first assertion fails. Set to true to aggregate all failures
              # runbook: nil,              # which runbook shall be displayed on failure that helps engineers resolve the issue
            }

            # an adapter class is expected to either be a singleton or a regular class
            # internally, this gem will attempt to call ".instance" or ".new" on the class
            # then the method `.call` is executed.
            config.adapters = {
              # other adapters: `Slack`, `Mock`, `Local`
              # the call method expectes 1 argument (e.g. of type DBLChecker::Check)
              persistance: DBLChecker::Adapters::Persistance::Local,
              # other adapters: `Mock`, `Local`
              # the call method expects 0 arguments
              job_executions: DBLChecker::Adapters::JobExecutions::Local,
            }
          end
        HEREDOC
      end

      def migration_file_content
        major = ::ActiveRecord::VERSION::MAJOR
        minor = ::ActiveRecord::VERSION::MINOR
        <<~HEREDOC
          class CreateDBLChecks < ActiveRecord::Migration[#{major}.#{minor}]
            def change
              create_table :dbl_checks, id: :uuid do |t|
                t.string :error
                t.string :app_version
                t.integer :timeout_after_seconds
                t.integer :execution_time_in_ms
                t.string :name
                t.string :description
                t.string :job_klass, null: false
                t.string :runbook
                t.datetime :finished_at, null: false

                t.timestamps
              end
            end

            add_index :dbl_checks, :job_klass
            add_index :dbl_checks, %i[job_klass finished_at], order: { finished_at: :desc }
          end
        HEREDOC
      end
    end
  end
end
