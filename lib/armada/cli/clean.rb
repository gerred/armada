module Armada
  class CleanCli < Thor

    desc "containers", "Remove all exited containers from a host(s)"
    option :hosts,            :type => :array,   :aliases => :h, :desc => "The docker host(s) to deploy to. This can be a comma sepearted list."
    option :ssh_gateway,      :type => :string,  :aliases => :G, :desc => "SSH Gateway Host"
    option :ssh_gateway_user, :type => :string,  :aliases => :U, :desc => "SSH Gateway User"
    option :force,            :type => :boolean, :aliases => :f, :desc => "Must specify the force option if you want the containers removed", :default => false, :lazy_default => true
    def containers
      Armada::Clean::Containers.new(options).run
    end

    desc "images", "Remove all untagged images from a host(s)"
    option :hosts,            :type => :array,   :aliases => :h, :desc => "The docker host(s) to deploy to. This can be a comma sepearted list."
    option :ssh_gateway,      :type => :string,  :aliases => :G, :desc => "SSH Gateway Host"
    option :ssh_gateway_user, :type => :string,  :aliases => :U, :desc => "SSH Gateway User"
    option :force,            :type => :boolean, :aliases => :f, :desc => "Must specify the force option if you want the containers removed", :default => false, :lazy_default => true
    option :prune,            :type => :boolean, :aliases => :p, :desc => "Whether to prune child images or not"
    def images
      Armada::Clean::Images.new(options).run
    end
  end
end
