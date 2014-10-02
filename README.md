## Description

Armada is a docker deployment tool which we originally forked from the [NewRelic Centurion](https://github.com/newrelic/centurion) project. It has since seen a huge refactor occur where we started using the [swipely/docker-api](https://github.com/swipely/docker-api) gem for interacting with our docker hosts instead of the mix of docker-cli and api calls that Centurion makes. The DSL is largely unchanged as it works really well for our intended purposes. 

## Installation

```
$ gem source -a http://gems.f4tech.com
$ gem install armada
```

## Writing your service descriptor
Currently, all descriptors live at [RallySoftware/armada-configs](https://github.com/RallySoftware/armada-configs) in the `config/armada` directory. 

Descriptors are in the form of a Rake task that uses a built-in DSL to make them
easy to write. Here's a sample config for a project called `zuulboy` that
would go into `config/armada/zuulboy.rake`:

```ruby
namespace :environment do
  task :common do
    env_vars LOG_DIR: "/home/zuul/logs/zuul"
    host_port 3000, container_port: 3000
    set :image, 'quay.io/rallysoftware/zuul'
    set :health_check_endpoint, '/metrics/healthcheck'
    set :health_check_port, 3000
  end

  desc 'Boulder environment'
  task :bld => :common do
    set_current_environment(:bld)
    host 'bld-zb-01:4243'
    host 'bld-zb-02:4243'
    host 'bld-zb-03:4243' 
  end

  desc 'Qwest Denver Production environment'
  task :qd => :common do
    set_current_environment(:qd)
    host 'qd-zb-01:4243'
    host 'qd-zb-02:4243'
    host 'qd-zb-03:4243'
  end

end
```

### Common Task
The common task is used to DRY up your descriptor file. It will always be loaded first allowing you to specify common elements of your deployment here and not repeat them throughout the rest of the file. You could also specify common elements here and then override them in later tasks if you need.

### Tasks
Each task should represent a logical unit of seperation from the rest. For instance, in the above descriptor we are describing each of the environments where the `zuulboy` project can reside. 

### Armada DSL
Armada provides a few convenience methods for adding items such as host and environment variables to a list.

#### host_port - Exposing container ports to the host system
The `host_port` method takes 2 parameters - the `port` on the host system and a map of options. The map of options has 3 values that can be set -
* `host_ip` - The ip address of the host interface. This way you can bind your host port to a particular ip address. Default is `0.0.0.0`
* `container_port` - The exposed port you are trying to map. **REQUIRED**
* `type` - The type of port you are exposing. Default is `tcp`.

**You can call this method multiple times to specify multiple exposed ports.**  
**If your container exposes a port and you do not want to map it to a static port on the host, Armada will make sure docker dynamically assigns it a port.**

Examples:

```ruby 
host_port 3000, container_port: 3000
```

```ruby 
host_port 3000, container_port: 3000, type: 'udp'
```

```ruby
host_port 3000, host_ip: '123.456.789' container_port: 3000, type: 'udp'
```

#### host_volume - Mapping container volumes to host volumes
The `host_volume` method takes two parameters - the host volume and a map of options. The map of options has 1 value that can be set.
* `container_volume` - The container volume to map to.

**You can call this method multiple times to specify multiple volumes**

Examples:
```ruby
host_volume '/var/log', container_volume: '/var/log:rw'
host_volume '/var/log', container_volume: '/var/log:ro'
```

#### env_vars - Key value pairs that are passed in as environment variables
The `env_vars` method take 1 parameter - a map of key value pairs.

Examples:
```ruby
env_vars JAVA_OPTS: '-Xmx2g -server -XX:+UseConcMarkSweepGC'
```

**You can call this method multiple times to specify multiple environmnet variables*

#### host - Specifies a host for a given task to interact with
The `host` method takes 1 parameter which is a string containing the `host` and `port` of the docker api you would like to interact with.

Examples:
```ruby
host 'bld-docker-01:4243'
```

**You can call this method multiple times to specify multiple hosts**

#### container_name - Override the container name
The `container_name` method takes 1 parameter which is a string to name the container when it is created on the host. Currently this is how we identify which container to shutdown during a rolling deploy.

Examples:
```ruby
container_name 'zuul'
```

#### setting other descriptor values
Some configuration options are not set using a DSL method. Instead you must call the `set` method. The current list of these options are:

```ruby
set :image, 'quay.io/rallysoftware/bag-boy'
set :tag, '0.1.0'
set :health_check_endpoint, '/_metrics/healthcheck'
set :health_check_port, 3100
set :deploy_retries, 60 #number of times to check if the container is up and healthy
set :deploy_wait_time, 1 #number of seconds to wait between each retry
```

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
