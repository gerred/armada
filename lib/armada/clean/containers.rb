module Armada
  module Clean
    class Containers
      def initialize(options)
        @hosts   = options[:hosts]
        @force   = options[:force]
        @options = options
      end

      def run
        Armada.ui.info "******* DRY RUN *******" unless @force
        @hosts.each_in_parallel do |host|
          docker_host = Armada::Host.create(host, @options)
          docker_host.get_all_containers.each do |container|
            running = container.json["State"]["Running"]
            paused = container.json["State"]["Paused"]
            unless running || paused
              begin
                Armada.ui.info "#{docker_host.host} -- #{container.json["Name"]} with id [#{container.id[0..11]}]"
                container.remove if @force
              rescue Exception => e
                Armada.ui.error "#{docker_host.host} -- unable to remove container #{container.json["Name"]} with id [#{container.id[0..11]}] because of the following error - #{e.message}"
              end
            end
          end
        end
      end
    end
  end
end
