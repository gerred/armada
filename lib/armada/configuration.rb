require 'rake'

module Armada
  module Configuration
    def self.load!(project, environment, cli_options = {})
      projects_dir = Dir.getwd()
      config_file  = "#{project}.rake"

      if File.exists?(File.join(projects_dir, config_file))
        Rake.load_rakefile File.join(File.join(projects_dir, config_file))
      elsif File.exists?(config_file)
        Rake.load_rakefile config_file
      else
        Armada.ui.error "Can't find '#{config_file}'!"
      end

      Object.send :include, Armada::DeployDSL
      task = Rake::Task["environment:#{environment}"]
      task.set_current_environment environment.to_sym
      task.invoke

      task_options = Thor::CoreExt::HashWithIndifferentAccess.new(env[environment.to_sym])
      env_vars = task_options[:env_vars]
      env_vars.merge!(cli_options[:env_vars]) if cli_options[:env_vars] # If I try and merge cli_options into task_options it overrides the task_options[:env_vars] hash.
      options = task_options.merge(cli_options)
      options[:env_vars]              = env_vars
      options[:tag]                   = 'latest' unless options[:tag]
      options[:health_check_endpoint] = '/'      unless options[:health_check_endpoint]
      options[:dockercfg]             = Armada::Docker::Config.load options[:dockercfg] if options[:dockercfg]
      options
    end
  end
end
