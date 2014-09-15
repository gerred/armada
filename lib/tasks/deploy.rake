require 'thread'
require 'excon'
require 'armada/deploy'
require 'armada/api'

task :stop do
  invoke 'deploy:stop'
end

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
    if fetch(:no_pull)
      info "--no-pull option specified: skipping pull"
      if fetch(:image_id)
        info "Using image id - #{fetch(:image_id)}"
      else
        raise "You must set an image_id if you are using the --no-pull option."
      end
    else
      invoke 'deploy:pull_image'
      invoke 'deploy:verify_image'
    end
  end

  # stop
  # - remote: list
  # - remote: stop
  task :stop do
    on_each_docker_host { |server| stop_container(server, fetch(:container_name)) }
  end

  # start
  # - remote: create
  # - remote: start
  # - remote: inspect container
  task :start_new do
    on_each_docker_host do |server|
      start_new_container(
        server,
        {
          :port_bindings  => fetch(:port_bindings),
          :binds          => fetch(:binds),
          :env_vars       => fetch(:env_vars),
          :container_name => fetch(:container_name)
        }
      )
    end
  end

  task :rolling_deploy do
    on_each_docker_host do |server|
      stop_container(server, fetch(:container_name))

      start_new_container(
        server,
        {
          :port_bindings  => fetch(:port_bindings),
          :binds          => fetch(:binds),
          :env_vars       => fetch(:env_vars),
          :container_name => fetch(:container_name)
        }
      )


      wait_for_http_status_ok(
        server,
        {
          :container_name           => fetch(:container_name),
          :health_check_port        => fetch(:health_check_port),
          :health_check_endpoint    => fetch(:health_check_endpoint, '/'),
          :rolling_deploy_retries   => fetch(:rolling_deploy_retries, 60),
          :rolling_deploy_wait_time => fetch(:rolling_deploy_wait_time, 1)
        }
      )

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
    info "Fetching image #{fetch(:image)}:#{fetch(:tag)} IN PARALLEL\n"
    auth = {}
    auth[:username] = fetch(:registry_username) if fetch(:registry_username)
    auth[:password] = fetch(:registry_password) if fetch(:registry_password)
    auth[:email]    = fetch(:registry_email)    if fetch(:registry_email)
    Armada::DockerServerGroup.new(fetch(:hosts)).each_in_parallel do |host|
      begin
        image = Docker::Image.create({:fromImage => fetch(:image), :tag => fetch(:tag)}, auth, host)
        set :image_id, image.id
      rescue Exception => e
        puts "error:#{e.inspect}"
      end
    end
  end

  task :verify_image do
    on_each_docker_host do |host|
      begin
        image = Docker::Image.get(fetch(:image_id), {}, host)
        if image.id[0..11] == fetch(:image_id)
          info "Image #{fetch(:image)}:#{fetch(:tag)} with ID:#{image.id[0..11]} found on #{host.url}"
        end
      rescue Exception
        raise "Did not find image #{fetch(:image_id)} on host #{host.url}!"
      end
    end
  end
end
