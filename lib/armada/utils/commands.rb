module Armada
  module Commands

    def self.stop(project, environment, options)
      options = Armada::Configuration.load!(project, environment, options)
      begin
        options[:hosts].each_in_parallel do |host|
          Armada.ui.info "Stopping container named [#{options[:container_name]}] on #{host}"
          docker_host = Armada::Host.create(host, options)
          container = Armada::Container.new(nil, docker_host, options)
          container.stop
        end
      rescue Exception => e
        Armada.ui.error "#{e.message} \n\n #{e.backtrace.join("\n")}"
        exit(1)
      end
    end 
  end
end
