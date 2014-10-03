module Armada
  class Deploy < Thor

    desc "parallel <project> <environment>", "Deploy the specified project to a set of hosts in parallel."
    option :hosts,        :type => :array,   :aliases => :h, :desc => "The docker host(s) to deploy to. This can be a comma sepearted list."
    option :image,        :type => :string,  :aliases => :i, :desc => "The image to use when deploying"
    option :tag,          :type => :string,  :aliases => :t, :desc => "Which version of the image to use", :lazy_default => "latest"
    option :username,     :type => :string,  :aliases => :u, :desc => "Docker registry username"
    option :password,     :type => :string,  :aliases => :p, :desc => "Docker registry password"
    option :health_check, :type => :boolean, :aliases => :c, :desc => "Perform health check of container", :default => false, :lazy_default => true
    option :env_vars,     :type => :hash,    :aliases => :e, :desc => "Environment Variables to pass into the container"
    def parallel(project, environment)
      @options = Armada::Configuration.load!(project, environment, @options)
      Armada.ui.info "Deploying the following image [#{@options[:image]}:#{@options[:tag]}] to these host(s) #{@options[:hosts].join(', ')} in PARALLEL"

      hosts = Armada::DockerHost.new(@options[:hosts])
      hosts.each_in_parallel do |connection|
        image = Armada::Image.new(@options, connection)
        image.pull

        container = Armada::Container.new(image, @options, connection)
        container.stop
        container.start
        container.wait_for_container
        container.health_check if @options[:health_check]
      end
    end

    desc "rolling <project> <environment>", "Perform a rolling deploy across a set of hosts."
    option :hosts,        :type => :array,   :aliases => :h, :desc => "The docker host(s) to deploy to. This can be a comma sepearted list."
    option :image,        :type => :string,  :aliases => :i, :desc => "The image to use when deploying"
    option :tag,          :type => :string,  :aliases => :t, :desc => "Which version of the image to use", :lazy_default => "latest"
    option :username,     :type => :string,  :aliases => :u, :desc => "Docker registry username"
    option :password,     :type => :string,  :aliases => :p, :desc => "Docker registry password"
    option :health_check, :type => :boolean, :aliases => :c, :desc => "Perform health check of container. Default is true", :default => true
    option :env_vars,     :type => :hash,    :aliases => :e, :desc => "Environment Variables to pass into the container"
    def rolling(project, environment)
      @options = Armada::Configuration.load!(project, environment, @options)
      Armada.ui.info "Deploying the following image [#{@options[:image]}:#{@options[:tag]}] to these host(s) #{@options[:hosts].join(', ')}"

      hosts = Armada::DockerHost.new(@options[:hosts])
      hosts.each do |connection|
        image = Armada::Image.new(@options, connection)
        image.pull

        container = Armada::Container.new(image, @options, connection)
        container.stop
        container.start
        container.wait_for_container
        container.health_check if options[:health_check]
      end
    end

  end
end
