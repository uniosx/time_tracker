# -*- encoding: utf-8 -*-
require File.expand_path('../lib/time_tracker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "time-tracker"
  gem.version       = TimeTracker::VERSION
  gem.authors       = ["Alec Tower"]
  gem.licenses      = ['MIT']
  gem.email         = ["alectower@gmail.com"]
  gem.description   = %q{Ruby based cli for project time tracking}
  gem.summary       = %q{Ruby based cli for project time tracking}
  gem.homepage      = "https://github.com/uniosx/time_tracker"
  gem.platform      = Gem::Platform::RUBY
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency 'rspec'
  gem.add_dependency 'typhoeus', '~> 0.6.8'
  gem.add_dependency 'sqlite3', '~> 1.3.3'
  gem.add_dependency 'sequel', '~> 4.13'
end
