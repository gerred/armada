# armada

A deployment tool for Docker. Takes containers from a Docker registry and runs
them on a fleet of hosts with the correct environment variables, host volume
mappings, and port mappings. Supports rolling deployments out of the box, and
makes it easy to ship applications to Docker servers.

## Installation


```
$ gem source -a http://gems.f4tech.com
$ gem install armada
```

### Writing configs

Configs are in the form of a Rake task that uses a built-in DSL to make them
easy to write. Here's a sample config for a project called "zuulboy" that
would go into `config/armada/zuulboy.rake`:

```ruby
namespace :environment do
  task :common do
    # set common attributes for your environment here!
    set :image, 'quay.io/rallysoftware/zuul'
    set :status_endpoint, '/metrics/healthcheck'
  end

  desc 'Boulder environment'
  task :bld => :common do
    set_current_environment(:bld)
    env_vars LOG_DIR: "/home/zuul/logs/zuul"
    host_port 3000, container_port: 3000
    host 'bld-zb-01:4243'
    host 'bld-zb-02:4243'
    host 'bld-zb-03:4243' 
  end

  desc 'Qwest Denver Production environment'
  task :qd => :common do
    set_current_environment(:qd)
    env_vars LOG_DIR: "/home/zuul/logs/zuul"
    host_port 3000, container_port: 3000
    host 'qd-zb-01:4243'
    host 'qd-zb-02:4243'
    host 'qd-zb-03:4243'
  end

end
```

This sets up a bld and qd environment and defines a `common` task
that will be run in either case. Note the dependency call in the task
definition for the `qd` and `bld` tasks.  Additionally, it
defines some host ports to map and sets which servers to deploy to. Some
configuration will provided to the containers at startup time, in the form of
environment variables.

All of the DSL items (`host_port`, `host_volume`, `env_vars`, `host`) can be
specified more than once and will append to the configuration.

#### DSL
##### host_port
##### host_volume
##### env_vars
##### host

### Deploying

armada supports a number of tasks out of the box that make working with
distributed containers easy.  Here are some examples:

#### Do a rolling deployment to a fleet of Docker servers

A rolling deployment will stop and start each container one at a time to make
sure that the application stays available from the viewpoint of the load
balancer. As the deploy runs, a health check will hit each container to ensure
that the application booted correctly. By default, this will be a GET request to
the root path of the application. This is configurable by adding
`set :health_check_endpoint, '/metrics/healthcheck'` in your config. The health check endpoint
must respond with a valid response in the 200 status range.

````bash
$ bundle exec armada -p zuulboy -e bld -a rolling_deploy
````

**Rolling Deployment Settings**:
You can change the following settings in your config to tune how the rolling
deployment behaves. Each of these is controlled with `set(:var_name, 'value')`.
These can be different for each environment or put into a common block if they
are the same everywhere. Settings are per-project.

 * `rolling_deploy_wait_time` => The amount of time to wait between unsuccessful
    health checks before retrying. Value in seconds. Defaults to 1 second.
 * `rolling_deploy_retries` => The number of times to retry a health check on
   the container once it is running. Defaults to 60

### Deploy a project to a fleet of Docker servers

This will hard stop, then start containers on all the specified hosts. This
is not recommended for apps where one endpoint needs to be available at all
times.

````bash
$ bundle exec armada -p zuulboy -e bld -a deploy
````

###List all the tags running on your servers for a particular project

Returns a nicely-formatted list of all the current tags and which machines they
are running on. Gives a unique list of tags across all hosts as well.  This is
useful for validating the state of the deployment in the case where something
goes wrong mid-deploy.

```bash
$ bundle exec armada -p zuulboy -e bld -a list:running_container_tags
```

###List all the containers currently running for this project

Returns a (as yet not very nicely formatted) list of all the containers for
this project on each of the servers from the config.

```bash
$ bundle exec armada -p zuulboy -e bld -a list:running_containers
```

### Armada Command line options
##### project <--project, -p>
##### environment <--environment, -e>
##### action <--action, -a>
##### image <--image, -i>
##### tag <--tag, -t>
##### hosts <--hosts, -h>
##### username <--username, -u>
##### password <--password, -s>
##### no-pull <--no-pull, -n>
