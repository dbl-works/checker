#!/usr/bin/env ruby

require 'slop'
require_relative '../version'

# https://github.com/leejarvis/slop#usage
opts = Slop.parse do |o|
  o.bool '-mr', '--mock-remote', 'mock requests to DBL servers'
  o.string '-e', '--environment', 'sets the RAILS_ENV variable'
  o.on '--version', 'print the version' do
    puts DBLChecker::VERSION
    exit
  end
end

ENV['RAILS_ENV'] = opts[:environment] unless opts[:environment].empty?
ENV['OPTS_MOCK'] = opts[:mock] unless opts[:mock].empty?
