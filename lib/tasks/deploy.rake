require 'thread'
require 'excon'
require 'armada/deploy'
require 'armada/api'

task :deploy do
  invoke 'deploy:get_image'
  invoke 'deploy:stop'
  invoke 'deploy:start_new'
  invoke 'deploy:cleanup'
end

task :rolling_deploy do
  invoke 'deploy:get_image'
  invoke 'deploy:rolling_deploy'
  invoke 'deploy:cleanup'
end

task :stop => ['deploy:stop']

namespace :deploy do
  include Armada::Deploy

  task :get_image do
    invoke 'deploy:pull_image'
    invoke 'deploy:verify_image'
  end

  # stop
  # - remote: list
  # - remote: stop
  task :stop do
    on_each_docker_host { |server| stop_containers(server, fetch(:port_bindings)) }
  end

  # start
  # - remote: create
  # - remote: start
  # - remote: inspect container
  task :start_new do
    on_each_docker_host do |server|
      start_new_container(
        server,
        fetch(:image_id),
        fetch(:port_bindings),
        fetch(:binds),
        fetch(:env_vars)
      )
    end
  end

  task :rolling_deploy do
    on_each_docker_host do |server|
      stop_containers(server, fetch(:port_bindings))

      start_new_container(
        server,
        fetch(:image_id),
        fetch(:port_bindings),
        fetch(:binds),
        fetch(:env_vars)
      )

      fetch(:port_bindings).each_pair do |container_port, host_ports|
        wait_for_http_status_ok(
          server,
          host_ports.first['HostPort'],
          fetch(:status_endpoint, '/'),
          fetch(:image),
          fetch(:tag),
          fetch(:rolling_deploy_wait_time, 5),
          fetch(:rolling_deploy_retries, 24)
        )
      end

      wait_for_load_balancer_check_interval
    end
  end

  #This should clean up all old containers by their name
  task :cleanup do
    on_each_docker_host do |host|
      cleanup_containers(host, fetch(:port_bindings))
    end
  end

  task :pull_image do
    if fetch(:no_pull)
      info "--no-pull option specified: skipping pull"
      next
    end
    $stderr.puts "Fetching image #{fetch(:image)}:#{fetch(:tag)} IN PARALLEL\n"

    auth = {}
    auth[:username] = fetch(:registry_username) if fetch(:registry_username)
    auth[:password] = fetch(:registry_password) if fetch(:registry_password)
    auth[:email]    = fetch(:registry_email)    if fetch(:registry_email)
    Armada::DockerServerGroup.new(fetch(:hosts)).each_in_parallel do |host|
      image = Docker::Image.create({:fromImage => fetch(:image), :tag => fetch(:tag)}, auth, host)
      set :image_id, image.id
    end
  end

  task :verify_image do
    on_each_docker_host do |host|
      image = Docker::Image.get(fetch(:image_id), {}, host)
      
      if image.id[0..11] == fetch(:image_id)
        debug "Image #{image.id[0..11]} found on #{host.url}"
      else
        raise "Did not find image #{fetch(:image_id)} on host #{host.url}!"
      end

      # Print the container config
      image.info["ContainerConfig"].each_pair do |key,value|
        debug "\t#{key} => #{value.inspect}"
      end
    end
  end
end