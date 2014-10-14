module Armada
  module Connection
    class Remote

      attr_reader :host, :port, :gateway
      def initialize(host, port = nil, gateway_host = nil, gateway_user = nil)
        @host, @port  = host.split(":")
        @port         = port ||= @port
        @gateway_host = gateway_host
        @gateway_user = gateway_user
        initialize_gateway!
      end

      def to_s
        "#{@host}:#{@port}"
      end

      def initialize_gateway!
        if @gateway_host
          @gateway       = Net::SSH::Gateway.new(@gateway_host, @gateway_user)
          @tunneled_port = @gateway.open(@host, @port)
        end
      end
    end
  end
end
