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

#### Common Task
The common task is used to DRY up your descriptor file. It will always be loaded first allowing you to specify common elements of your deployment here and not repeat them throughout the rest of the file. You could also specify common elements here and then override them in later tasks if you need.

#### Tasks
Each task should represent a logical unit of seperation from the rest. For instance, in the above descriptor we are describing each of the environments where the `zuulboy` project can reside. 

#### Armada DSL
Armada provides a few convenience methods for adding items such as host and environment variables to a list.

##### host_port - Exposing container ports to the host system
The `host_port` method takes 2 parameters - the `port` on the host system and a map of options. The map of options has 3 values that can be set -
* `host_ip` - The ip address of the host interface. This way you can bind your host port to a particular ip address. Default is `0.0.0.0`
* `container_port` - The exposed port you are trying to map
* `type` - The type of port you are exposing. Default is `tcp`.


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
