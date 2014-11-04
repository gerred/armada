module Armada
  module Deploy
    class Parallel

      attr_reader :project, :environment, :options
      def initialize(project, environment, options)
        @project     = project
        @environment = environment
        @options     = Armada::Configuration.load!(project, environment, options)
      end

      def run
        Armada.ui.info "Deploying the following image [#{@options[:image]}:#{@options[:tag]}] to these host(s) #{@options[:hosts].join(', ')} in PARALLEL"

        begin
          @options[:hosts].each_in_parallel do |host|
            docker_host = Armada::Host.create(host, options)
            image = docker_host.get_image @options[:image], @options[:tag], @options
            image.pull

            container = Armada::Container.new(image, docker_host, @options)
            container.stop
            container.start

            if @options[:health_check] && @options[:health_check_port]
              ports = container.ports

              if ports.empty?
                raise "No ports exposed for this container. Please expose a port for the health check or use the --no-health-check option!"
              end

              begin
                health_check_port = ports["#{@options[:health_check_port]}/tcp"][0]["HostPort"]
              rescue Exception => e
                raise "Could not find the host port for [#{health_check_port}]. Make sure you put the container port as the :health_check_port."
              end

              health_check = Armada::Connection::HealthCheck.new(
                host,
                health_check_port,
                @options[:health_check_endpoint],
                @options[:health_check_delay],
                @options[:health_check_retries],
                @options[:ssh_gateway],
                @options[:ssh_gateway_user]
              )

              raise "Health check failed! - #{host}" unless health_check.run
            end
          end
        rescue Exception => e
          Armada.ui.error "#{e.message} \n\n #{e.backtrace.join("\n")}"
          exit(1)
        end
      end
    end
  end
end
