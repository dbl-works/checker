# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
require 'rails/test_help'

require 'rails/test_unit/reporter'
Rails::TestUnitReporter.executable = 'bin/test'

require 'dbl-checker'

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('fixtures', __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = "#{ActiveSupport::TestCase.fixture_path}/files"
  ActiveSupport::TestCase.fixtures :all
end

DBLChecker.configure do |config|
  config.app_version = 'some-git-sha'
  config.adapters = {
    persistance: DBLChecker::Adapters::Persistance::Mock,
    job_executions: DBLChecker::Adapters::JobExecutions::Mock,
  }
end
