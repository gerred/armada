require_relative 'api'
require 'excon'

module Armada; end

module Armada::Deploy

  FAILED_CONTAINER_VALIDATION = 100

  def stop_container(host, container_name)
    container = Armada::Api.get_container_by_name(host, container_name, {:all => true})
    if container
      info "Stopping old container #{container.id[0..7]} (#{container_name})"
      container.kill

      info "Deleting old container #{container.id[0..7]} (#{container_name})"
      begin
        container.remove
      rescue Exception => e
        error "Could not remove container #{container.id[0..7]} (#{container_name}) on host #{URI.parse(host.url).host}:#{URI.parse(host.url).port} -- #{e.response.data[:body]}"
      end
    else
      info "No container found with the name #{container_name}"
    end
  end

  def wait_for_http_status_ok(host, opts = {})
    info 'Waiting for the container to come up'
    1.upto(opts[:rolling_deploy_retries]) do
      if container_up?(host, opts[:container_name]) && http_status_ok?(host, opts[:health_check_port], opts[:health_check_endpoint])
        info 'Container is up!'
        break
      end

      info "Waiting #{opts[:rolling_deploy_wait_time]} seconds to test the #{URI.parse(host.url).host}:#{opts[:health_check_port]}#{opts[:health_check_endpoint]} endpoint..."
      sleep(opts[:rolling_deploy_wait_time])
    end

    unless http_status_ok?(host, opts[:health_check_port], opts[:health_check_endpoint])
      error "Failed to validate started container on #{URI.parse(host.url).host}:#{opts[:health_check_port]}"
      exit(FAILED_CONTAINER_VALIDATION)
    end
  end

  def container_up?(host, container_name)
    container = Armada::Api.get_container_by_name(host, container_name)
    
    if container
      time = Time.now - Time.parse(container.json["State"]["StartedAt"])
      info "Found container up for #{time.round(2)} seconds"
      return true
    end

    false
  end

  def http_status_ok?(host, port, endpoint)
    url = "http://#{URI.parse(host.url).host}:#{port}#{endpoint}"
    response = begin
      Excon.get(url)
    rescue Excon::Errors::SocketError
      warn "Failed to connect to #{url}, no socket open."
      nil
    end

    return false unless response
    return true if response.status >= 200 && response.status < 300

    warn "Got HTTP status: #{response.status}" 
    false
  end

  def wait_for_load_balancer_check_interval
    sleep(fetch(:rolling_deploy_check_interval, 5))
  end

  def cleanup_containers(host, public_port)
    old_containers = Armada::Api.get_non_running_containers(host)
    old_containers.each do |container| 
      # need better cleanup algorithm
      #container_name = container.info["Name"].gsub!(/^\//, "")
      #info "Removing the following container - #{container_name} #{container.id[0..11]}"
      #container.remove unless container_name =~ /spoon*/
    end
  end

  def container_config_for(host, opts = {})
    container_config = {
      'Image'        => fetch(:image_id),
      'Hostname'     => URI.parse(host.url).host,
    }

    if opts[:port_bindings]
      container_config['ExposedPorts'] ||= {}
      opts[:port_bindings].keys.each do |port|
        container_config['ExposedPorts'][port] = {}
      end
    end

    if opts[:env_vars]
      container_config['Env'] = opts[:env_vars].map { |k,v| "#{k}=#{v}" }
    end

    if opts[:binds]
      container_config['Volumes'] = opts[:binds].inject({}) do |memo, v|
        memo[v.split(/:/).last] = {}
        memo
      end
      container_config['VolumesFrom'] = 'parent'
    end

    if opts[:container_name]
      container_config['name'] = opts[:container_name]
      #should we do soemthing if container namae isnt set?
    end
    container_config
  end

  def start_new_container(host, opts = {})
    container_config = container_config_for(host, opts)
    start_container_with_config(host, opts[:binds], opts[:port_bindings], container_config)
  end

  private
  
  def start_container_with_config(host, volumes, port_bindings, container_config)
    info "Creating new container for image - #{fetch(:image)}:#{fetch(:tag)} (#{fetch(:image_id)}) with name #{fetch(:container_name)}"

    begin
      container = Docker::Container.create(container_config, host)
    rescue Excon::Errors::Conflict => e
      raise "Error occured on #{URI.parse(host.url).host}:#{URI.parse(host.url).port}: #{e.response.data[:body]}"
    end

    host_config = {}
    # Map some host volumes if needed
    host_config['Binds'] = volumes if volumes && !volumes.empty?
    # Bind the ports
    host_config['PortBindings'] = port_bindings if port_bindings
    host_config['PublishAllPorts'] = true

    info "Starting new container #{container.id[0..11]}"
    container = container.start!(host_config)
    
    info "Inspecting new container #{container.id[0..11]}:"
    info container.top.inspect

    container
  end
end
