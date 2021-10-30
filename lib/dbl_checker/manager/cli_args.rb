#!/usr/bin/env ruby

require 'slop'
require_relative '../version'

# https://github.com/leejarvis/slop#usage
opts = Slop.parse do |o|
  o.bool '-m', '--mock_remote', 'mock requests to DBL servers'
  o.string '-e', '--environment', 'sets the RAILS_ENV variable'
  o.string '-c', '--config', 'path to the config file'
  o.string '-i', '--inflections', 'path to an Active Support inflection file'
  o.on '--version', 'print the version' do
    puts DBLChecker::VERSION
    exit
  end
end

ENV['RAILS_ENV'] = opts[:environment] if ENV['RAILS_ENV'].nil?
ENV['RAILS_ENV'] ||= 'development'
ENV['DBL_CHECKER_MOCK_REMOTE'] = @opts&.mock_remote?.to_s
ENV['DBL_CHECKER_CONFIG_PATH'] = opts[:config].to_s
ENV['DBL_CHECKER_INFLECTIONS_PATH'] = opts[:inflections].to_s
