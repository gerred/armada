require 'spec_helper'

describe Armada::Container do
  let(:container_name) { "some_container" }
  let(:container_id) { "123456789abc123" }
  let(:image_id) { "123456789abc123" }
  let(:image_name) { "quay.io/someorg/someimage" }
  let(:tag) { "latest" }
  let(:options) {{
    :container_name => container_name,
    :image          => image_name,
    :tag            => tag
  }}

  let(:docker_host) { Armada::Host.create("http://foo-01:4243") }
  let(:docker_connection) { ::Docker::Connection.new("http://foo-01:4243", {})}
  let(:armada_image) { Armada::Image.new(docker_host, options) }
  let(:docker_image) { ::Docker::Image.new(docker_connection, "id" => image_id) }
  let(:docker_container) { ::Docker::Container.send(:new, docker_connection, {'id' => container_id, 'Names' => ["/#{container_name}"]}) }
  let(:armada_container) { Armada::Container.new(armada_image, docker_host, options) }
  let(:config) {{
    :port_bindings => { "1111/tcp" => [{"HostIp" => "0.0.0.0", "HostPort" => "1111"}],
                        "2222/udp" => [{"HostIp" => "0.0.0.0", "HostPort" => "2222"}]},
    :env_vars      => { "KEY" => "VALUE" },
    :binds         => [ "/host/log:/container/log" ],
    :restart_policy => { "MaximumRetryCount" => 5, "Name" => "always" },
    :container_config => { "CreateConfigKey" => "CreateConfigValue" },
    :host_config => { "StartConfigKey" => "StartConfigValue" },
  }}

  describe "#stop" do
    context "when the container exists" do
      before { docker_host.should_receive(:get_container).and_return(docker_container) }
      it "should call kill and remove" do
        expect(armada_container).to receive(:kill)
        expect(armada_container).to receive(:remove)
        armada_container.stop
      end
    end

    context "when the container does not exist" do
      before { docker_host.should_receive(:get_container).and_return(nil) }
      it "should not call kill and remove" do
        expect(armada_container).not_to receive(:kill)
        expect(armada_container).not_to receive(:remove)
        expect(Armada.ui).to receive(:warn).with(/No container found with the name/)
        armada_container.stop
      end
    end
  end

  describe "#kill" do
    context "when the container exists" do
      before { docker_host.should_receive(:get_container).and_return(docker_container) }
      it "should call kill on the container" do
        expect(armada_container.container).to receive(:kill)
        armada_container.kill
      end

      it "should call kill on the docker container" do
        expect(docker_container).to receive(:kill)
        armada_container.kill
      end
    end

    context "when the container does not exist" do
      before { docker_host.should_receive(:get_container).and_return(nil) }
      it "should not call kill" do
        allow_message_expectations_on_nil
        expect(armada_container.container).not_to receive(:kill)
        armada_container.kill
      end
    end
  end

  describe "#remove" do
    context "when the container exists" do
      before { docker_host.should_receive(:get_container).and_return(docker_container) }
      it "should call remove on the container" do
        expect(armada_container.container).to receive(:remove)
        armada_container.remove
      end

      it "should call remove on the docker container" do
        expect(docker_container).to receive(:remove)
        armada_container.remove
      end

      it "should catch any exception that is thrown" do
        expect(docker_container).to receive(:remove).and_raise(Exception.new("Could not remove container"))
        expect(Armada.ui).to receive(:error).with(/Could not remove container/)
        armada_container.remove
      end
    end

    context "when the container does not exist" do
      before { docker_host.should_receive(:get_container).and_return(nil) }
      it "should not call remove" do
        allow_message_expectations_on_nil
        expect(armada_container.container).not_to receive(:remove)
        armada_container.remove
      end
    end
  end

  describe ".create_container_config" do
    subject { Armada::Container.create_container_config(image_id, container_name, "hostname", config) }
    it { should include("Image"        => "123456789abc123") }
    it { should include("Hostname"     => "hostname") }
    it { should include("name"         => "some_container") }
    it { should include("ExposedPorts" => { "1111/tcp" => {}, "2222/udp" => {}}) }
    it { should include("Env"          => ["KEY=VALUE", "HOST=hostname"]) }
    it { should include("Volumes"      => { "/container/log" => {}}) }
    it { should include("VolumesFrom"  => "parent") }
    it { should include("RestartPolicy" => { "MaximumRetryCount" => 5, "Name" => "always" }) }
    it { should include("CreateConfigKey" => "CreateConfigValue") }
  end

  describe ".create_host_config" do
    subject { Armada::Container.create_host_config(config) }
    it { should include("Binds" => ["/host/log:/container/log"])}
    it { should include("PortBindings" => {"1111/tcp" => [{"HostIp" => "0.0.0.0", "HostPort" => "1111"}],
                                    "2222/udp" => [{"HostIp" => "0.0.0.0", "HostPort" => "2222"}]}) }
    it { should include("PublishAllPorts" => true) }
    it { should include("StartConfigKey" => "StartConfigValue") }
  end

end
