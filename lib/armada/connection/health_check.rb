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

      def healthy?
        response = begin
          Excon.get("http://#{health_check_host}:#{health_check_port}#{@endpoint}")
        rescue Exception => e
          return false
        end

        return false unless response
        return true if response.status >= 200 && response.status < 300

        warn "Got HTTP status: #{response.status}"
        false
      end

      private

      def health_check_host
        return "localhost" if @gateway
        return @host
      end

      def health_check_port
        return @tunneled_port ||= port
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
