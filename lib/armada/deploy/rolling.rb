module Armada
  module Deploy
    class Rolling

      attr_reader :project, :environment, :options
      def initialize(project, environment, options)
        @project     = project
        @environment = environment
        @options     = Armada::Configuration.load!(project, environment, options)
      end

      def run
        Armada.ui.info "Deploying the following image [#{@options[:image]}:#{@options[:tag]}] to these host(s) #{@options[:hosts].join(', ')}"
        begin
          @options[:hosts].each_in_parallel do |host|
            docker_connection = Armada::Connection::Docker.new(host, @options[:ssh_gateway], @options[:ssh_gateway_user])
            Armada::Image.create(@options, docker_connection).pull
          end

          @options[:hosts].each do |host|
            docker_connection = Armada::Connection::Docker.new(host, @options[:ssh_gateway], @options[:ssh_gateway_user])
            image = Armada::Image.create(@options, docker_connection)
            container = Armada::Container.new(image, @options, docker_connection)
            container.stop
            container.start

            if @options[:health_check]
              raise "Health check failed! - #{host}" unless Armada::Connection::HealthCheck.new(host, @options[:health_check_port],
                                                                                                      @options[:health_check_endpoint],
                                                                                                      @options[:health_check_delay],
                                                                                                      @options[:health_check_retries],
                                                                                                      @options[:ssh_gateway],
                                                                                                      @options[:ssh_gateway_user]).run
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