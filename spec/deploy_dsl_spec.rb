require 'spec_helper'

class DeployDSLTest
  extend Armada::DeployDSL
end

describe Armada::DeployDSL do
  before do
    DeployDSLTest.clear_env
    DeployDSLTest.set_current_environment('test')
  end

  it 'adds new env_vars to the existing ones' do
    DeployDSLTest.set(:env_vars, { 'SHAKESPEARE' => 'Hamlet' })
    DeployDSLTest.env_vars('DICKENS' => 'David Copperfield')

    expect(DeployDSLTest.fetch(:env_vars)).to include('SHAKESPEARE' => 'Hamlet', 'DICKENS' => 'David Copperfield')
  end

  it 'adds hosts to the host list' do
    DeployDSLTest.set(:hosts, [ 'host1' ])
    DeployDSLTest.host('host2')
    expect(DeployDSLTest.fetch(:hosts)).to include("host1", "host2")
  end

  it 'adds the restart policy' do
    DeployDSLTest.restart_policy({:foo => "bar"})
    expect(DeployDSLTest.fetch(:restart_policy)).to eq({:foo => "bar"})
  end

  describe '#localhost' do
    it 'adds a host by reading DOCKER_HOST if present' do
      expect(ENV).to receive(:[]).with('DOCKER_HOST').and_return('tcp://127.1.1.1:4240')
      DeployDSLTest.localhost
      expect(DeployDSLTest.fetch(:hosts)).to include("127.1.1.1:4240")
    end

    it 'adds a host defaulting to loopback if DOCKER_HOST is not present' do
      expect(ENV).to receive(:[]).with('DOCKER_HOST').and_return(nil)
      DeployDSLTest.localhost
      expect(DeployDSLTest.fetch(:hosts)).to include("127.0.0.1")
    end
  end

  describe '#host_port' do
    it 'raises unless passed container_port in the options' do
      expect { DeployDSLTest.host_port(666, {}) }.to raise_error(ArgumentError, /:container_port/)
    end

    it 'adds new bind ports to the list' do
      dummy_value = { '666/tcp' => ['value'] }
      DeployDSLTest.set(:port_bindings, dummy_value)
      DeployDSLTest.host_port(999, container_port: 80)

      expect(DeployDSLTest.fetch(:port_bindings)).to include(dummy_value.merge('80/tcp' => [{ 'HostIp' => '0.0.0.0', 'HostPort' => '999' }]))
    end

    it 'does not explode if port_bindings is empty' do
      expect { DeployDSLTest.host_port(999, container_port: 80) }.not_to raise_error
    end

    it 'raises if invalid options are passed' do
      expect { DeployDSLTest.host_port(80, asdf: 'foo') }.to raise_error(ArgumentError, /invalid key!/)
    end
  end

  describe '#host_volume' do
    it 'raises unless passed the container_volume option' do
      expect { DeployDSLTest.host_volume('foo', {}) }.to raise_error(ArgumentError, /:container_volume/)
    end

    it 'raises when passed bogus options' do
      expect { DeployDSLTest.host_volume('foo', bogus: 1) }.to raise_error(ArgumentError, /invalid key!/)
    end

    it 'adds new host volumes' do
     expect(DeployDSLTest.fetch(:binds)).to be_nil
     DeployDSLTest.host_volume('volume1', container_volume: '/dev/sdd')
     DeployDSLTest.host_volume('volume2', container_volume: '/dev/sde')
     expect(DeployDSLTest.fetch(:binds)).to eq %w{ volume1:/dev/sdd volume2:/dev/sde }
    end
  end

end
