require_relative 'cli/deploy'
require_relative 'cli/inspect'
require_relative 'cli/clean'

module Armada
  class Cli < Thor

    def initialize(*args)
      super(*args)

      if @options[:quiet]
        Aramda.ui.mute!
      end

      @options = options.dup
    end

    class_option :quiet,
      desc: "Silence all informational output",
      type: :boolean,
      aliases: "-q",
      default: false

    desc "version", "Display Aramda version."
    def version
      Armada.ui.info "#{Armada.executable_name} #{Armada::VERSION}"
    end

    desc "deploy SUBCOMMAND ...ARGS", "Deploy a docker container"
    subcommand "deploy", Armada::DeployCli

    desc "inspect SUBCOMMAND ...ARGS", "Info about the state of a docker host"
    subcommand "inspect", Armada::InspectCli

    desc "clean SUBCOMMAND ...ARGS", "Clean a docker host(s)"
    subcommand "clean", Armada::CleanCli

    desc "stop <project> <environment>", "Stop running containers for the project in the environment. Use --force to actually stop the containers"
    option :hosts,            :type => :array,   :aliases => :h, :desc => "The docker host(s) to deploy to. This can be a comma sepearted list."
    option :ssh_gateway,      :type => :string,  :aliases => :G, :desc => "SSH Gateway Host"
    option :ssh_gateway_user, :type => :string,  :aliases => :U, :desc => "SSH Gateway User"
    option :force,            :type => :boolean, :aliases => :f, :desc => "Must specify the force option if you want the containers stopped", :default => false, :lazy_default => true
    def stop(project, environment)
      Armada::Commands.stop(project, environment, options)
    end

  end
end
