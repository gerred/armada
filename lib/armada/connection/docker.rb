module Armada
  module Connection
    class Docker < Remote

      attr_reader :connection
      def initialize(host, gateway_host = nil, gateway_user = nil)
        super(host, nil, gateway_host, gateway_user)
        @connection = create_connection
      end

      def to_s
        "#{@host}:#{@port}"
      end

      private
      def create_connection
        return ::Docker::Connection.new("http://localhost:#{@tunneled_port}", {}) if @gateway
        return ::Docker::Connection.new("http://#{@host}:#{@port}", {})
      end
    end
  end
end
