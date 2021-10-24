require 'active_support/all'
require 'dbl_checker/assertion_failed'
require 'dbl_checker/check'
require 'dbl_checker/configuration'
require 'dbl_checker/job'
require 'dbl_checker/remote'
require 'dbl_checker/server_error'
require 'dbl_checker/slack_notifier'

DBLChecker.configure do |config|
  config.logger = nil
end

module DBLChecker; end
