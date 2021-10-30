#!/usr/bin/env ruby

require 'slop'
require_relative '../version'

# https://github.com/leejarvis/slop#usage
opts = Slop.parse do |o|
  o.bool '-m', '--mock_remote', 'mock requests to DBL servers'
  o.string '-e', '--environment', 'sets the RAILS_ENV variable'
  o.string '-c', '--config', 'path to the config file'
  o.on '--version', 'print the version' do
    puts DBLChecker::VERSION
    exit
  end
end

ENV['RAILS_ENV'] = opts[:environment] if ENV['RAILS_ENV'].nil?
ENV['DBL_CHECKER_MOCK_REMOTE'] = "#{@opts&.mock_remote?}"
ENV['DBL_CHECKER_CONFIG_PATH'] = opts[:config]
