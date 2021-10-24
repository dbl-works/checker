lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dbl_checker/version'

Gem::Specification.new do |s|
  s.platform      = Gem::Platform::RUBY
  s.name          = 'dbl-checker'
  s.version       = DBLChecker::VERSION
  s.summary       = 'Regularly assert expectations for your application still hold true.'
  s.description   = 'Regularly assert expectations for your application still hold true.'

  s.required_ruby_version = '>= 2.6'

  s.author        = 'DBL'
  s.email         = 'checker@dbl.works'
  s.license       = 'MIT'

  s.files         = Dir['lib/**/*.rb', 'spec/**/*', 'bin/*']
  s.require_path  = 'lib'
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency 'activesupport', '>= 5.2'
  s.add_dependency 'faraday', '~> 1.0' # Slack webhooks and persistance on remote servers

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'parse_a_changelog'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop-dbl'
end
