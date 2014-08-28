module Armada
  class DockerHost

    def initialize(hosts)
      @hosts = hosts
    end

    def each_in_parallel(&block)
      threads = @hosts.map do |host|
        connection = Docker::Connection.new("http://#{host}", {})
        Thread.new { block.call(connection) }
      end

      threads.each { |t| t.join }
    end

    def each(&block)
      @hosts.each do |host|
        block.call(Docker::Connection.new("http://#{host}", {}))
      end
    end
  end
end
