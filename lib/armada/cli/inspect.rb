module Armada
  class InspectCli < Thor

    desc "short", "Return basic information on all running containers for a given host"
    option :hosts, :type => :array, :aliases => :h, :desc => "The Docker host to inspect"
    def short
    #   Armada.ui.info "Gathering information for #{@options[:hosts].join(', ')}..."

    #   hosts = Armada::.new(@options[:hosts])
    #   hosts.each do |connection|
    #     running_containers = []
    #     Armada::Container.all(connection).each do |container|
    #       state = container.json["State"]
    #       if state["Running"]
    #         running_containers <<
    #         {
    #           :container_id   => container.id[0..10],
    #           :container_name => container.json["Name"],
    #           :pid            => state["Pid"],
    #           :uptime         => Time.seconds_to_string(Time.now - Time.parse(state["StartedAt"])),
    #         }
    #       end
    #     end
    #     tp running_containers
    #   end
    end
  end
end
