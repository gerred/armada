require_relative 'cli/deploy'
require_relative 'cli/inspect'

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
    subcommand "deploy", Armada::Deploy

    desc "inspect SUBCOMMAND ...ARGS", "Info about the state of a docker host"
    subcommand "inspect", Armada::Inspect
  end
end