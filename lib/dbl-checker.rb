# external dependencies
require 'active_support/all'

# adapters
require 'dbl_checker/adapters/job_executions/dbl_checker_platform'
require 'dbl_checker/adapters/job_executions/mock'
require 'dbl_checker/adapters/job_executions/local'
require 'dbl_checker/adapters/persistance/dbl_checker_platform'
require 'dbl_checker/adapters/persistance/mock'
require 'dbl_checker/adapters/persistance/local'
require 'dbl_checker/adapters/persistance/slack'
require 'dbl_checker/adapters/validator'

# core
require 'dbl_checker/check'
require 'dbl_checker/configuration'
require 'dbl_checker/job'

# custom errors
require 'dbl_checker/errors/dbl_checker_error'
require 'dbl_checker/errors/assertion_failed_error'
require 'dbl_checker/errors/server_error'
require 'dbl_checker/errors/config_error'

# manager
require 'dbl_checker/manager/client'

DBLChecker.configure do |config|
  config.logger = nil
end

module DBLChecker; end
