module Armada
  class Container

    attr_reader :id, :container, :name
    def initialize(image, docker_host, options)
      @docker_host = docker_host
      @id          = nil
      @image       = image
      @name        = options[:container_name]
      @container   = docker_host.get_container(@name)
      @options     = options

      now_in_ns = Integer(Time.now.to_f * 1000000.0)
      @options[:binds] ||= []
      @options[:binds] << "/var/log/containers/#{@name}/#{SecureRandom.uuid}:/var/log/service"
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
      info "Creating new container for image - #{@image.name}:#{@image.tag} with image id (#{@image.id}) with container name #{@name}"
      container_config = Armada::Container.create_container_config(@image.id, @name, @docker_host.host, @options)
      begin
        @container = create(container_config)
        @id = @container.id
        info "Starting new container #{@id[0..11]}"
        @container.start!(Armada::Container.create_host_config(@options))
      rescue Exception => e
        raise "Error occured on #{@docker_host.host}:#{@docker_host.port}: #{e.message}"
      end
    end

    def create(container_config)
      ::Docker::Container.create(container_config, @docker_host.connection)
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

    def self.create_host_config(options)
      host_config = options[:host_config] || {}
      host_config['Binds'] = options[:binds] if options[:binds] && !options[:binds].empty?
      host_config['PortBindings'] = options[:port_bindings] if options[:port_bindings]
      host_config['PublishAllPorts'] = true
      host_config['Privileged'] = options[:privileged] || false
      host_config
    end

    def self.create_container_config(image_id, container_name, host, options = {})
      container_config = options[:container_config] || {}
      options[:env_vars][:HOST] = host

      container_config['Image'] = image_id || options[:image]
      container_config['Hostname'] = options[:hostname] || host

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

      if options[:restart_policy]
        container_config["RestartPolicy"] = options[:restart_policy]
      end

      container_config
    end

    def ports
      return @container.json["NetworkSettings"]["Ports"]
    end

    private

    def info(message)
      Armada.ui.info "#{@docker_host.host} -- #{message}"
    end

    def warn(message)
      Armada.ui.warn "#{@docker_host.host} -- #{message}"
    end

    def error(message)
      Armada.ui.error "#{@docker_host.host} -- #{message}"
    end
  end
end
