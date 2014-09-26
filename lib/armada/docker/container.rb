module Armada
  class Container

    attr_reader :id, :container, :name
    def initialize(image, options, connection)
      @id             = nil
      @image          = image
      @name           = options[:container_name]
      @connection     = connection
      @container      = find_by_name(@name)
      @options        = options
      @host           = URI.parse(connection.url).host
    end

    def stop
      info "Stopping all running containers named - #{@name}"
      if @container
        kill
        remove
      else
        info "No container found with the name #{@name}"
      end
    end

    def start
      info "Creating new container for image - #{@image.name}:#{@image.tag} (#{@image.id}) with name #{@name}"
      container_config = create_container_config(@image.id, @name, @host, @options)
      begin
        @container = create(container_config)
        @id = container.id
      rescue Excon::Errors::Conflict => e
        uri = URI.parse(connection.url)
        raise "Error occured on #{uri.host}:#{uri.port}: #{e.response.data[:body]}"
      end

      info "Starting new container #{@id[0..11]}"
      container.start!(create_host_config(@options))
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
        unless healthy?(@host, @options[:health_check_endpoint], @options[:health_check_port])
          info "Still waiting for health check to pass at - :#{@options[:health_check_port]}#{@options[:health_check_endpoint]} endpoint..." if i % (@options[:deploy_retries]/10) == 0
          sleep(@options[:deploy_wait_time])
        end
      end

      unless healthy?(@host, @options[:health_check_endpoint], @options[:health_check_port])
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

    def find_by_name(name)
      Container::all(@connection).each do |found_container|
        container = get(found_container.id)
        return container if container.info["Name"].gsub!(/^\//, "") == name
      end
      nil
    end

    def self.all(connection)
      Docker::Container.all({:all => true}, connection)
    end

    def get(id)
      Docker::Container.get(id, {}, @connection)
    end

    def create(container_config)
      Docker::Container.create(container_config, @connection)
    end

    def kill
      return if @container.nil?
      info "Stopping old container #{@container.id[0..7]} (#{@container.info['Name']})"
      @container.kill
    end

    def remove
      return if container.nil?
      info "Deleting old container #{@container.id[0..7]} (#{@container.info['Name']})"
      begin
        @container.remove
      rescue Exception
        error "Could not remove container #{@container.id[0..7]} (#{@container.info['Name']})"
      end
    end

    def create_host_config(options)
      host_config = {}
      host_config['Binds'] = options[:binds] if options[:binds] && !options[:binds].empty?
      host_config['PortBindings'] = options[:port_bindings] if options[:port_bindings]
      host_config['PublishAllPorts'] = true
      host_config
    end

    def create_container_config(image_id, container_name, host, options = {})
      container_config = {
        'Image'        => @image.id,
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

    def healthy?(host, endpoint, port)
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
