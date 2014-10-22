module Armada
  class Host
    attr_reader :docker_connection
    def initialize(docker_connection)
      @docker_connection = docker_connection
    end

    def get_image(name, tag, options = {})
      begin
        image = ::Docker::Image.get("#{name}:#{tag}", {}, connection)
        options[:docker_image] = image
        options[:id] = image.id if image
      rescue Exception => e
        Armada.ui.warn "#{host} -- #{e.message}"
      ensure
        return Image.new(self, options)
      end
    end

    def get_image_by_id(id, options)
      begin
        image = ::Docker::Image.get(id, {}, connection)
        options[:docker_image] = image
        options[:id] = id
      rescue Exception => e
        Armada.ui.warn "#{host} -- #{e.message}"
      ensure
        return Image.new(self, options)
      end
    end

    def get_all_images
      ::Docker::Image.all({:all => true}, connection)
    end

    def get_all_containers
      ::Docker::Container.all({:all => true}, connection)
    end

    def get_container(id)
      begin
        return ::Docker::Container.get(id, {}, connection)
      rescue Exception => e
        return nil
      end
    end

    def connection
      @docker_connection.connection
    end

    def host
      @docker_connection.host
    end

    def port
      @docker_connection.port
    end

    def to_s
      "#{host}:#{port} -- #{connection}"
    end

    def self.create(host, options = {})
      Host.new(Armada::Connection::Docker.new(host, options[:ssh_gateway], options[:ssh_gateway_user]))
    end
  end
end
