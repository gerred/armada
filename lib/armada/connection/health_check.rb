module Armada
  module Connection
    class HealthCheck < Remote

      attr_reader :endpoint
      def initialize(host, port, endpoint = nil, delay = nil, retries = nil, gateway_host = nil, gateway_user = nil)
        super(host, port, gateway_host, gateway_user)
        @endpoint = endpoint ||= '/'
        @delay    = delay    ||= 1
        @retries  = retries  ||= 60
      end

      def to_s
        "#{@host}:#{@port}#{@endpoint}"
      end

      def run
        info "Performing health check at - :#{@port}#{@endpoint}. Will retry every #{@delay} second(s) for #{@retries} times."
        1.upto(@retries) do |i|
          initialize_gateway!
          unless healthy?
            info "Still waiting for health check to pass at - :#{@port}#{@endpoint} endpoint..." if i % (@retries/10) == 0
            sleep(@delay)
          end
        end

        unless healthy?
          raise "Failed to validate health check on #{self}"
        else
          info "Health Check succeeded!"
        end
      end

      private

      def health_check_host
        return "localhost" if @gateway
        return @host
      end

      def health_check_port
        return @tunneled_port ||= port
      end

      def healthy?
        response = begin
          http = Net::HTTP.new(health_check_host, health_check_port)
          http.read_timeout = 1
          request = Net::HTTP::Get.new(@endpoint)
          http.request(request)
        rescue Exception => e
          return false
        end

        return false unless response
        return true if response.code.to_i >= 200 && response.code.to_i < 300

        warn "Got HTTP status: #{response.status}"
        false
      end

      def info(message)
        Armada.ui.info "#{@host} -- #{message}"
      end

      def warn(message)
        Armada.ui.warn "#{@host} -- #{message}"
      end
    end
  end
end
