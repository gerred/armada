# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'armada/version'

Gem::Specification.new do |spec|
  spec.name          = 'docker-armada'
  spec.version       = Armada::VERSION
  spec.authors       = ['Jonathan Chauncey', 'Matt Farrar', 'Darrell Hamilton']
  spec.summary       = 'Deploy utility for docker containers'
  spec.description   = 'Deploy utility for docker containers'
  spec.homepage      = 'https://github.com/RallySoftware/armada'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'excon', '~> 0.33'
  spec.add_dependency 'net-ssh'
  spec.add_dependency 'net-ssh-gateway'
  spec.add_dependency 'docker-api', '~> 1.13'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'awesome_print'
  spec.add_dependency 'table_print'
  spec.add_dependency 'conjur-cli'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.14.0'
  spec.add_development_dependency 'thor-scmversion', '< 1.6.0'
  spec.add_development_dependency 'geminabox', '~> 0.10'
  spec.add_development_dependency 'webmock'

  spec.required_ruby_version = '>= 1.9.3'
end
