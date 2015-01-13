# Copyright (c) 2014 New Relic, Inc.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'singleton'

module Armada::DeployDSL
  class CurrentEnvironmentNotSetError < RuntimeError; end

  class Store < Hash
    include Singleton
  end

  def env
    Store.instance
  end

  def fetch(key, default=nil, &block)
    env[current_environment][key] || default
  end

  def any?(key)
    value = fetch(key)
    if value && value.respond_to?(:any?)
      value.any?
    else
      !fetch(key).nil?
    end
  end

  def set(key, value)
    env[current_environment][key] = value
  end

  def delete(key)
    env[current_environment].delete(key)
  end

  def set_current_environment(environment)
    env[:current_environment] = environment
    env[environment] ||= {}
    env_vars ENVIRONMENT: environment.to_s.downcase
  end

  def current_environment
    raise CurrentEnvironmentNotSetError.new('Must set current environment') unless env[:current_environment]
    env[:current_environment]
  end

  def clear_env
    env.clear
  end

  def container_name(name)
    set(:container_name, name)
  end

  def env_vars(new_vars)
    current = fetch(:env_vars, {})
    new_vars.each_pair do |new_key, new_value|
      current[new_key.to_s] = new_value
    end
    set(:env_vars, current)
  end

  def host(hostname)
    current = fetch(:hosts, [])
    current << hostname
    set(:hosts, current)
  end

  def hostname(hostname)
    set(:hostname, hostname)
  end

  def localhost
    # DOCKER_HOST is like 'tcp://127.0.0.1:4243'
    docker_host_uri = URI.parse(ENV['DOCKER_HOST'] || "tcp://127.0.0.1")
    host_and_port = [docker_host_uri.host, docker_host_uri.port].compact.join(':')
    host(host_and_port)
  end

  def host_port(port, options)
    validate_options_keys(options, [ :host_ip, :container_port, :type ])
    require_options_keys(options,  [ :container_port ])

    add_to_bindings(
      options[:host_ip] || '0.0.0.0',
      options[:container_port],
      port,
      options[:type] || 'tcp'
    )
  end

  def restart_policy(opts)
    set(:restart_policy, opts)
  end

  def secret_value(key)
    `conjur variable value #{key}`
  end

  def public_port_for(port_bindings)
    # {'80/tcp'=>[{'HostIp'=>'0.0.0.0', 'HostPort'=>'80'}]}
    first_port_binding = port_bindings.values.first
    first_port_binding.first['HostPort']
  end

  def host_volume(volume, options)
    validate_options_keys(options, [ :container_volume ])
    require_options_keys(options,  [ :container_volume ])

    binds            = fetch(:binds, [])
    container_volume = options[:container_volume]

    binds << "#{volume}:#{container_volume}"
    set(:binds, binds)
  end

  def container_config(cfg)
    set(:container_config, cfg)
  end

  def start_config(cfg)
    set(:start_config, cfg)
  end

  def privileged
    set(:privileged, true)
  end

  private

  def add_to_bindings(host_ip, container_port, port, type='tcp')
    ports = fetch(:port_bindings, {})
    ports["#{container_port.to_s}/#{type}"] = [{'HostIp' => host_ip, 'HostPort' => port.to_s}]
    set(:port_bindings, ports)
  end

  def validate_options_keys(options, valid_keys)
    unless options.keys.all? { |k| valid_keys.include?(k) }
      raise ArgumentError.new('Options passed with invalid key!')
    end
  end

  def require_options_keys(options, required_keys)
    missing = required_keys.reject { |k| options.keys.include?(k) }

    unless missing.empty?
      raise ArgumentError.new("Options must contain #{missing.inspect}")
    end
  end
end
