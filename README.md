## Description

Armada is a docker deployment tool which we originally forked from the [NewRelic Centurion](https://github.com/newrelic/centurion) project. It has since seen a huge refactor occur where we started using the [swipely/docker-api](https://github.com/swipely/docker-api) gem for interacting with our docker hosts instead of the mix of docker-cli and api calls that Centurion makes. The DSL is largely unchanged as it works really well for our intended purposes.

## Installation

```
$ gem sources -a http://gems.f4tech.com
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
    env_vars LOG_DIR: '/home/zuul/logs/zuul'
    container_name 'zuul'
    set :image, 'quay.io/rallysoftware/zuul'
    set :health_check_endpoint, '/metrics/healthcheck'
    set :health_check_port, 3000
    host_port 3000, container_port: 3000
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
The `common` task is used to DRY up your descriptor file. It will always be loaded first allowing you to specify common elements of your deployment here and not repeat them throughout the rest of the file. You could also specify common elements here and then override them in later tasks if you need.

### Tasks
Each task should represent a logical unit of seperation from the rest. For instance, in the above descriptor we are describing each of the environments where the `zuulboy` project can reside.

### Armada DSL
Armada provides a few convenience methods for adding items such as host and environment variables to a list.

#### host_port - Exposing container ports to the host system
The `host_port` method takes 2 parameters - the `port` on the host system and a map of options. The map of options has 3 values that can be set:
* `host_ip` - The ip address of the host interface. This way you can bind your host port to a particular ip address. Default is `0.0.0.0`
* `container_port` - The exposed port you are trying to map. **REQUIRED**
* `type` - The type of port you are exposing. Default is `tcp`.

**You can call this method multiple times to specify multiple exposed ports.**
**If your container exposes a port and you do not want to map it to a static port on the host, Armada will make sure docker dynamically assigns it a port.**

Examples:

```ruby
host_port 3000, container_port: 3000
host_port 8282, container_port: 8080, type: 'udp'
host_port 5991, host_ip: '123.456.789' container_port: 7001, type: 'udp'
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
env_vars DB_USER: 'someuser'
```

**You can call this method multiple times to specify multiple environment variables**

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

#### Docker Restart Policy
You can add your own Docker Restart policy, see the [API documentation](https://docs.docker.com/reference/api/docker_remote_api_v1.15/#create-a-container)

```ruby
restart_policy { "Name" => "always" }
restart_policy { "Name" => "on-failure", "MaximumRetryCount" => 5 }
```

#### Setting other descriptor values
Some configuration options are not set using a DSL method. Instead you must call the `set` method. The current list of these options are:

```ruby
set :image, 'quay.io/rallysoftware/bag-boy'
set :tag, '0.1.0'
set :health_check_endpoint, '/_metrics/healthcheck'
set :health_check_port, 3100
set :deploy_retries, 60 #number of times to check if the container is up and healthy
set :deploy_wait_time, 1 #number of seconds to wait between each retry
```

#### Raw Container Config
If you want to use a docker feature not yet exposed through the armadafile, you can include a raw container config, and the rest of the armadafile will be applied on top of it.

```ruby
container_config { "Cmd" => [ "date" ] }
```

## CLI
The CLI is written using [Thor](http://whatisthor.com/). Below is current commands that can be executed using the Armada gem.

### Deploy
The following tasks can be used when deploying a container to a set of docker hosts.

#### Parallel
Deploys a project to all hosts in parallel. The following steps are run within their own thread. This means that some steps may complete on some hosts faster than other. Also means that all machines will be down at roughly the same time.

Command:
```bash
armada deploy parallel <project> <environment> <options>
```

Steps performed by this task:
 1. Pull the version of the image you wish to deploy. If `--no-pull` is specified this will not occur.
 1. Stop all running container(s) with the name you are wishing to use.
 1. Start the new container(s)
 1. Wait for the container(s) to come up
 1. If you used the `--health-check` option it will then wait until the health check passes

Options:
* `hosts` - This will override the hosts defined in the descriptor
* `image` - This will override the image defined in the descriptor
* `tag` - This will override the tag defined in the descriptor
* `username` - The username for the private registry of your image, if specified you must also specify `password`
* `password` - The password for the private registry of your image, if specified you must also specify `username`
* `health-check` - Default is true. You can specify `--no-health-check` to not perform a health check during a rolling deploy.
* `env-vars` - This allows for new or overriding env vars to be passed in from the command line. This option can only be specified once, but may take mulitple values.
* `ssh-gateway` - This allows you to perform commands against a remote docker host(s) using a gateway.
* `ssh-gateway-user` - The user opening the gateway
* `pull` - Allows you to specify whether to pull the specified image or not. Defaults to true.
* `dockercfg` - This is the path to the .dockercfg file which can be used instead of specifying the username and password for the registry. Defaults to `~/.dockercfg`

Examples:
```bash
armada deploy parallel foo prod --hosts my-prod-host:5555 --username username --password secretsauce --health-check
armada deploy parallel foo prod --env-vars PORT:4343 DB_USER:"FOO"
```

#### Rolling
This will deploy the project in a rolling fashion. Meaning it will only act on 1 host at a time.

Command:
```bash
armada deploy rolling <project> <environment> <options>
```

Steps performed by this task:
 1. Pull the version of the image you wish to deploy. If `--no-pull` is specified this will not occur.
 1. Stop all running container(s) with the name you are wishing to use.
 1. Start the new container(s)
 1. Wait for the container(s) to come up
 1. Perform a health check. You can specify the `--no-health-check` option to skip this step.
 1. Move to next host (if applicable), sequentially repeating the steps above until all hosts are complete.

Options:
* `hosts` - This will override the hosts defined in the descriptor
* `image` - This will override the image defined in the descriptor
* `tag` - This will override the tag defined in the descriptor
* `username` - The username for the private registry of your image, if specified you must also specify `password`
* `password` - The password for the private registry of your image, if specified you must also specify `username`
* `health-check` - Default is true. You can specify `--no-health-check` to not perform a health check during a rolling deploy.
* `env-vars` - This allows for new or overriding env vars to be passed in from the command line. This option can only be specified once, but may take mulitple values.
* `ssh-gateway` - This allows you to perform commands against a remote docker host(s) using a gateway.
* `ssh-gateway-user` - The user opening the gateway
* `pull` - Allows you to specify whether to pull the specified image or not. Defaults to true.
* `dockercfg` - This is the path to the .dockercfg file which can be used instead of specifying the username and password for the registry. Defaults to `~/.dockercfg`

Examples:
```bash
armada deploy rolling foo prod --hosts my-prod-host:5555 --username username --password secretsauce --no-health-check
armada deploy rolling foo prod --env-vars PORT:4343 DB_USER:"FOO"
```

## Contributing
Rally welcomes any bug fixes or new functionality. Please feel free to open an issue or pull request with a fix or even a test that reproduces a bug. We cannot promise an immediate response but we will try hard to get back to you as soon as possible.

## Maintainers
[Jonathan Chauncey (jchauncey)](https://github.com/jchauncey)
[Darrel Hamilton (zeroem)](https://github.com/zeroem)

## License
Copyright (c) 2013 Rally Software Development Corp

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
