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
  spec.add_dependency 'net-ssh', '~> 2.9'
  spec.add_dependency 'net-ssh-gateway', '~> 1.2'
  spec.add_dependency 'docker-api', '= 1.18'
  spec.add_dependency 'thor', '~> 0.19'
  spec.add_dependency 'awesome_print', '~> 1.2'
  spec.add_dependency 'table_print', '~> 1.5'
  spec.add_dependency 'conjur-cli', '~> 4.17'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 2.14.0'
  spec.add_development_dependency 'thor-scmversion', '< 1.6.0'
  spec.add_development_dependency 'geminabox', '~> 0.10'
  spec.add_development_dependency 'webmock', '~> 1.19'

  spec.required_ruby_version = '>= 1.9.3'
end
