#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__), '..', 'lib')
require_relative '../lib/Armada'
require 'capistrano_dsl'

self.extend Capistrano::DSL
self.extend Armada::DeployDSL
self.extend Armada::Logging

#
# Initialize Rake engine
#
require 'rake'
Rake.application.options.trace = true

task_dir = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. lib tasks}))
Dir.glob(File.join(task_dir, '*.rake')).each { |file| load file }

#
# Trollop option setup
#
require 'trollop'

opts = Trollop::options do
  opt :project,     'project (blog, forums...)',                   type: String, required: true,  short: '-p'
  opt :environment, "environment (production, staging...)",        type: String, required: true,  short: '-e'
  opt :action,      'action (deploy, list...)',                    type: String, default: 'list', short: '-a'
  opt :image,       'image (yourco/project...)',                   type: String, required: false, short: '-i'
  opt :tag,         'tag (latest...)',                             type: String, required: false, short: '-t'
  opt :hosts,       'hosts, comma separated',                      type: String, required: false, short: '-h'
  opt :docker_path, 'path to docker executable (default: docker)', type: String, default: 'docker', short: '-d'
  opt :no_pull,     'Skip the pull_image step',                    type: :flag, default: false, long: '--no-pull'
end

set_current_environment(opts[:environment].to_sym)
set :project, opts[:project]
set :environment, opts[:environment]

# Load the per-project config and execute the task for the current environment
projects_dir = File.join(Dir.getwd(), 'config', 'Armada')
config_file  = "#{opts[:project]}.rake"
if File.exists?(File.join(projects_dir, config_file))
  load File.join(File.join(projects_dir, config_file))
elsif File.exists?(config_file)
  load config_file
else
  raise "Can't find '#{config_file}'!"
end
invoke("environment:#{opts[:environment]}")

# Override the config with command line values if given
set :image, opts[:image] if opts[:image]
set :tag,   opts[:tag] if opts[:tag]
set :hosts, opts[:hosts].split(",") if opts[:hosts]

# Default tag should be "latest"
set :tag, 'latest' unless any?(:tag)
set :docker_registry, 'https://registry.hub.docker.com/'

# Specify a path to docker executable
set :docker_path, opts[:docker_path]

set :no_pull, opts[:no_pull]

invoke(opts[:action])