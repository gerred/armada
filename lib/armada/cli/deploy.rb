module Armada
  class DeployCli < Thor

    no_commands {
      def self.common_options
        option :hosts,            :type => :array,   :aliases => :h, :desc => "The docker host(s) to deploy to. This can be a comma sepearted list."
        option :image,            :type => :string,  :aliases => :i, :desc => "The image to use when deploying"
        option :tag,              :type => :string,  :aliases => :t, :desc => "Which version of the image to use", :lazy_default => "latest"
        option :username,         :type => :string,  :aliases => :u, :desc => "Docker registry username"
        option :password,         :type => :string,  :aliases => :p, :desc => "Docker registry password"
        option :health_check,     :type => :boolean, :aliases => :c, :desc => "Perform health check of container. Default is true", :default => true
        option :env_vars,         :type => :hash,    :aliases => :e, :desc => "Environment Variables to pass into the container"
        option :pull,             :type => :boolean,                 :desc => "Whether to pull the image from the docker registry", :default => true
        option :ssh_gateway,      :type => :string,  :aliases => :G, :desc => "SSH Gateway Host"
        option :ssh_gateway_user, :type => :string,  :aliases => :U, :desc => "SSH Gateway User"
        option :dockercfg,        :type => :string,                  :desc => "dockercfg file to use for authenticating", :default => '~/.dockercfg'
      end
    }

    desc "parallel <project> <environment>", "Deploy the specified project to a set of hosts in parallel."
    DeployCli.common_options
    def parallel(project, environment)
      Armada::Deploy::Parallel.new(project, environment, options).run
    end

    desc "rolling <project> <environment>", "Perform a rolling deploy across a set of hosts."
    DeployCli.common_options
    def rolling(project, environment)
      Armada::Deploy::Rolling.new(project, environment, options).run
    end
  end
end
