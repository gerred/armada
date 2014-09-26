require 'thor'
require 'awesome_print'
require 'table_print'

require_relative 'armada/cli'
require_relative 'armada/configuration'
require_relative 'armada/docker'
require_relative 'armada/deploy_dsl'
require_relative 'armada/ui'
require_relative 'armada/utils'
require_relative 'armada/thor'

module Armada
  Thor::Base.shell.send(:include, Armada::UI)

  class << self
    def root
      @root ||= Pathname.new(File.expand_path('../', File.dirname(__FILE__)))
    end

    def executable_name
      File.basename($PROGRAM_NAME)
    end

    def ui
      @ui ||= Thor::Base.shell.new
    end
  end
end
