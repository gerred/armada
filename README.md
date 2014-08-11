armada
=========

A deployment tool for Docker. Takes containers from a Docker registry and runs
them on a fleet of hosts with the correct environment variables, host volume
mappings, and port mappings. Supports rolling deployments out of the box, and
makes it easy to ship applications to Docker servers.

Installation
------------

```
$ gem install armada
```

With rbenv you will now need to do an `rbenv rehash` and the commands should
be available. With a non-rbenv install, assuming the gem dir is in your path,
the commands should just work now.

Configuration
-------------

Armada expects to find configuration tasks in the current working directory.
Soon it will also support reading configuration from etcd.

We recommend putting all your configuration for multiple applications into a
single repo rather than spreading it around by project. This allows a central
choke point on configuration changes between applications and tends to work
well with the hand-off in many organizations between the build and deploy
steps. If you only have one application, or don't need this you can
decentralize the config into each repo.

It will look for configuration files in either `./config/armada` or `.`.

The pattern at New Relic is to have a configs repo with a `Gemfile` that
sources the armada gem. If you want armada to set up the structure for
you and to create a sample config, you can simply run `armadize` once you
have the Ruby Gem installed.

armada ships with a simple scaffolding tool that will setup a new config repo for
you, as well as scaffold individual project configs. Here's how you run it:

```bash
$ armadize -p <your_project>
```

`armadize` relies on Bundler being installed already. Running the command
will have the following effects:

 * Ensure that a `config/armada` directory exists
 * Scaffold an example config for your project (you can specify the registry)
 * Ensure that a Gemfile is present
 * Ensure that armada is in the Gemfile (if absent it just appends it)

Any time you add a new project you can scaffold it in the same manner even
in the same repo.

###Writing configs

If you used `armadize` you will have a base config scaffolded for you.
But you'll still need to specify all of your configuration.

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

Deploying
---------

armada supports a number of tasks out of the box that make working with
distributed containers easy.  Here are some examples:

###Do a rolling deployment to a fleet of Docker servers

A rolling deployment will stop and start each container one at a time to make
sure that the application stays available from the viewpoint of the load
balancer. As the deploy runs, a health check will hit each container to ensure
that the application booted correctly. By default, this will be a GET request to
the root path of the application. This is configurable by adding
`set(:status_endpoint, '/somewhere/else')` in your config. The status endpoint
must respond with a valid response in the 200 status range.

````bash
$ bundle exec armada -p zuulboy -e bld -a rolling_deploy
````

**Rolling Deployment Settings**:
You can change the following settings in your config to tune how the rolling
deployment behaves. Each of these is controlled with `set(:var_name, 'value')`.
These can be different for each environment or put into a common block if they
are the same everywhere. Settings are per-project.

 * `rolling_deploy_check_interval` => Controls how long armada will wait after
    seeing a container as up before moving on to the next one. This should be
    slightly longer than your load balancer check interval. Value in seconds.
    Defaults to 5 seconds.
 * `rolling_deploy_wait_time` => The amount of time to wait between unsuccessful
    health checks before retrying. Value in seconds. Defaults to 5 seconds.
 * `rolling_deploy_retries` => The number of times to retry a health check on
   the container once it is running. This count multiplied by the
   `rolling_deployment_wait_time` is the total time armada will wait for
   an individual container to come up before giving up as a failure. Defaults
   to 24 attempts.

###Deploy a project to a fleet of Docker servers

This will hard stop, then start containers on all the specified hosts. This
is not recommended for apps where one endpoint needs to be available at all
times.

````bash
$ bundle exec armada -p zuulboy -e bld -a deploy
````

###Deploy a bash console on a host

This will give you a command line shell with all of your existing environment
passed to the container. The `CMD` from the `Dockerfile` will be replaced
with `/bin/bash`. It will use the first host from the host list.

````bash
$ bundle exec armada -p zuulboy -e bld -a deploy_console
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

###List registry images

Returns a list of all the images for this project in the registry.

````bash
$ bundle exec armada -p zuulboy -e bld -a list
````

### Release process
* rake spec 
* rake release

Future Additions
----------------

We're currently looking at the following feature additions:

 * [etcd](https://github.com/coreos/etcd) integration for configs and discovery
 * Add the ability to show all the available tasks on the command line
 * Certificate authentication
 * Customized tasks
 * Dynamic host allocation to a pool of servers
