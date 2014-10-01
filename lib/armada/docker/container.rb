module Armada
  class Container

    attr_reader :id, :container, :name
    def initialize(image, options, connection)
      @id             = nil
      @image          = image
      @name           = options[:container_name]
      @connection     = connection
      @container      = Armada::Container.find_by_name(@name, @connection)
      @options        = options
      @host           = URI.parse(connection.url).host
    end

    def stop
      if @container
        info "Stopping the running container named - #{@name}"
        kill
        remove
      else
        warn "No container found with the name #{@name}"
      end
    end

    def start
      info "Creating new container for image - #{@image.name}:#{@image.tag} (#{@image.id}) with name #{@name}"
      container_config = Armada::Container.create_container_config(@image.id, @name, @host, @options)
      begin
        @container = create(container_config)
        @id = @container.id
        info "Starting new container #{@id[0..11]}"
        @container.start!(Armada::Container.create_host_config(@options))
      rescue Excon::Errors::Conflict => e
        uri = URI.parse(@connection.url)
        raise "Error occured on #{uri.host}:#{uri.port}: #{e.response.data[:body]}"
      end
    end

    def wait_for_container
      info 'Waiting for the container to come up'
      1.upto(@options[:deploy_retries]) do
        if container_up?
          info 'Container is up!'
          break
        end
        sleep(@options[:deploy_wait_time])
      end
    end

    def health_check
      info "Performing health check at - :#{@options[:health_check_port]}#{@options[:health_check_endpoint]}. Will retry every #{@options[:deploy_wait_time]} second(s) for #{@options[:deploy_retries]} times."
      1.upto(@options[:deploy_retries]) do |i|
        unless Armada::Container.healthy?(@host, @options[:health_check_endpoint], @options[:health_check_port])
          info "Still waiting for health check to pass at - :#{@options[:health_check_port]}#{@options[:health_check_endpoint]} endpoint..." if i % (@options[:deploy_retries]/10) == 0
          sleep(@options[:deploy_wait_time])
        end
      end

      unless Armada::Container.healthy?(@host, @options[:health_check_endpoint], @options[:health_check_port])
        error "Failed to validate started container on #{@host}:#{@options[:health_check_port]}"
        raise
      else
        info "Container passed health check!"
      end
    end

    # I wonder if we should also check ot see if the container has exited here?
    def container_up?
      if @container
        time = Time.now - Time.parse(@container.json["State"]["StartedAt"])
        info "Found container up for #{time.round(2)} seconds"
        return true
      end
      false
    end

    def create(container_config)
      Docker::Container.create(container_config, @connection)
    end

    def kill
      return if @container.nil?
      info "Stopping old container #{@container.id[0..7]} (#{@name})"
      @container.kill
    end

    def remove
      return if @container.nil?
      info "Deleting old container #{@container.id[0..7]} (#{@name})"
      begin
        @container.remove
      rescue Exception => e
        error "Could not remove container #{@container.id[0..7]} (#{@name}).\nException was: #{e.message}"
      end
    end

    def self.find_by_name(name, connection)
      name = "/#{name}" unless name.start_with?("/")
      Armada::Container.all(connection).each do |container|
        return container if container.info["Names"].include? name
      end
      nil
    end

    def self.all(connection)
      Docker::Container.all({:all => true}, connection)
    end

    def self.get(id, connection)
      Docker::Container.get(id, {}, connection)
    end

    def self.create_host_config(options)
      host_config = {}
      host_config['Binds'] = options[:binds] if options[:binds] && !options[:binds].empty?
      host_config['PortBindings'] = options[:port_bindings] if options[:port_bindings]
      host_config['PublishAllPorts'] = true
      host_config
    end

    def self.create_container_config(image_id, container_name, host, options = {})
      container_config = {
        'Image'        => image_id,
        'Hostname'     => host,
      }

      if options[:port_bindings]
        container_config['ExposedPorts'] ||= {}
        options[:port_bindings].keys.each do |port|
          container_config['ExposedPorts'][port] = {}
        end
      end

      if options[:env_vars]
        container_config['Env'] = options[:env_vars].map { |k,v| "#{k}=#{v}" }
      end

      if options[:binds]
        container_config['Volumes'] = options[:binds].inject({}) do |memo, v|
          memo[v.split(/:/).last] = {}
          memo
        end
        container_config['VolumesFrom'] = 'parent'
      end

      if container_name
        container_config['name'] = container_name
        #should we do soemthing if container name isnt set?
      end
      container_config
    end

    def self.healthy?(host, endpoint, port)
      url = "http://#{host}:#{port}#{endpoint}"
      response = begin
        Excon.get(url)
      rescue Excon::Errors::SocketError
        false
      end

      return false unless response
      return true if response.status >= 200 && response.status < 300

      warn "Got HTTP status: #{response.status}"
      false
    end

    private

    def info(message)
      Armada.ui.info "#{URI.parse(@connection.url).host} -- #{message}"
    end

    def warn(message)
      Armada.ui.warn "#{URI.parse(@connection.url).host} -- #{message}"
    end

    def error(message)
      Armada.ui.error "#{URI.parse(@connection.url).host} -- #{message}"
    end

  end
end
