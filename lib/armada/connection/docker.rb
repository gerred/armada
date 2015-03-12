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
        return ::Docker::Connection.new("#{scheme}://localhost:#{@tunneled_port}", connection_opts) if @gateway
        return ::Docker::Connection.new("#{scheme}://#{@host}:#{@port}", connection_opts)
      end

      def scheme
        ENV['DOCKER_CERT_PATH'] ? 'https' : 'http'
      end

      def connection_opts
        opts = {}
        if cert_path = ENV['DOCKER_CERT_PATH']
          opts[:client_cert] = File.join(cert_path, 'cert.pem')
          opts[:client_key] = File.join(cert_path, 'key.pem')
          opts[:ssl_ca_file] = File.join(cert_path, 'ca.pem')
          opts[:ssl_verify_peer] = @gateway ? false : ENV['DOCKER_TLS_VERIFY'] == '1'
        end

        opts
      end
    end
  end
end
