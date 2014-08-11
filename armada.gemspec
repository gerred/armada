# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'armada/version'

Gem::Specification.new do |spec|
  spec.name          = 'armada'
  spec.version       = Armada::VERSION
  spec.authors       = ['Jonathan Chauncey', 'Matt Farrar']
  spec.summary       = 'Deploy utility for docker containers'
  spec.description   = 'Deploy utility for docker containers'
  spec.homepage      = 'https://github.com/RallySoftware/armada'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'trollop'
  spec.add_dependency 'excon', '~> 0.33'
  spec.add_dependency 'logger-colors'
  spec.add_dependency 'docker-api', '~> 1.13'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.14.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'geminabox'

  spec.required_ruby_version = '>= 1.9.3'
end
