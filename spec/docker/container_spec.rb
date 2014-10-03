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

  let(:connection) { Docker::Connection.new("http://foo-01", {}) }
  let(:armada_image) { Armada::Image.new(options, connection) }
  let(:docker_image) { Docker::Image.new(connection, "id" => image_id) }
  let(:docker_container) { Docker::Container.send(:new, connection, {'id' => container_id, 'Names' => ["/#{container_name}"]}) }
  let(:armada_container) { Armada::Container.new(armada_image, options, connection) }
  let(:config) {{
    :port_bindings => { "1111/tcp" => [{"HostIp" => "0.0.0.0", "HostPort" => "1111"}],
                        "2222/udp" => [{"HostIp" => "0.0.0.0", "HostPort" => "2222"}]},
    :env_vars      => { "KEY" => "VALUE" },
    :binds         => [ "/host/log:/container/log" ]
  }}

  describe "#stop" do
    context "when the container exists" do
      before { Armada::Container.should_receive(:find_by_name).and_return(docker_container) }
      it "should call kill and remove" do
        expect(armada_container).to receive(:kill)
        expect(armada_container).to receive(:remove)
        armada_container.stop
      end
    end

    context "when the container does not exist" do
      before { Armada::Container.should_receive(:find_by_name).and_return(nil) }
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
      before { Armada::Container.should_receive(:find_by_name).and_return(docker_container) }
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
      before { Armada::Container.should_receive(:find_by_name).and_return(nil) }
      it "should not call kill" do
        allow_message_expectations_on_nil
        expect(armada_container.container).not_to receive(:kill)
        armada_container.kill
      end
    end
  end

  describe "#remove" do
    context "when the container exists" do
      before { Armada::Container.should_receive(:find_by_name).and_return(docker_container) }
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
      before { Armada::Container.should_receive(:find_by_name).and_return(nil) }
      it "should not call remove" do
        allow_message_expectations_on_nil
        expect(armada_container.container).not_to receive(:remove)
        armada_container.remove
      end
    end
  end

  describe "#create" do
    before { Armada::Container.should_receive(:find_by_name).and_return(nil) }
    it "should call create on Docker::Container" do
      expect(Docker::Container).to receive(:create).with({}, connection)
      armada_container.create({})
    end
  end

  describe "#container_up?" do
    context "when the container has a StartedAt entry" do
      it "should return true" do
        Armada::Container.should_receive(:find_by_name).and_return(docker_container)
        docker_container.should_receive(:json).and_return({"State" => { "StartedAt" => Time.now.to_s }})
        armada_container.container_up?.should be_true
      end
    end


    context "when the container has no StartedAt entry" do
      it "should return false" do
        Armada::Container.should_receive(:find_by_name).and_return(nil)
        armada_container.container_up?.should be_false
      end
    end
  end

  describe ".find_by_name" do
    let(:foo_container) { Docker::Container.send(:new, connection, {'id' => container_id, 'Names' => ["/foo_container"]}) }
    let(:bar_container) { Docker::Container.send(:new, connection, {'id' => container_id, 'Names' => ["/bar_container"]}) }
    let(:baz_container) { Docker::Container.send(:new, connection, {'id' => container_id, 'Names' => ["/baz_container"]}) }

    it "should find matching container by name excluding the leading slash" do
      Armada::Container.should_receive(:all).and_return([foo_container, bar_container, baz_container, docker_container])
      Armada::Container.find_by_name(container_name, connection).info["Names"].should include("/#{container_name}")
    end

    it "should return nil if no matching container is found" do
      Armada::Container.should_receive(:all).and_return([foo_container, bar_container, baz_container])
      Armada::Container.find_by_name(container_name, connection).should be_nil
    end
  end

  describe ".create_container_config" do
    subject { Armada::Container.create_container_config(image_id, container_name, "hostname", config) }
    it { should include("Image"        => "123456789abc123") }
    it { should include("Hostname"     => "hostname") }
    it { should include("name"         => "some_container") }
    it { should include("ExposedPorts" => { "1111/tcp" => {}, "2222/udp" => {}}) }
    it { should include("Env"          => ["KEY=VALUE"]) }
    it { should include("Volumes"      => { "/container/log" => {}}) }
    it { should include("VolumesFrom"  => "parent") }
  end

  describe ".create_host_config" do
    subject { Armada::Container.create_host_config(config) }
    it { should include("Binds" => ["/host/log:/container/log"])}
    it { should include("PortBindings" => {"1111/tcp" => [{"HostIp" => "0.0.0.0", "HostPort" => "1111"}],
                                    "2222/udp" => [{"HostIp" => "0.0.0.0", "HostPort" => "2222"}]}) }
    it { should include("PublishAllPorts" => true) }
  end

  describe ".healthy?" do
    context "when the container health check passes" do
      let(:mock_ok_status)  { double('http_status_ok').tap { |s| s.stub(status: 200) } }
      before { expect(Excon).to receive(:get).with(any_args).and_return(mock_ok_status) }

      it "should return true" do
        Armada::Container.healthy?("foo-01", "/metrics/healthcheck", 2181).should be_true
      end
    end

    context "when the container health check fails" do
      let(:mock_bad_status)  { double('http_status_ok').tap { |s| s.stub(status: 500) } }
      before { expect(Excon).to receive(:get).with(any_args).and_return(mock_bad_status) }

      it "should return false" do
        Armada::Container.healthy?("foo-01", "/metrics/healthcheck", 2181).should be_false
      end
    end

    context "when the container health check throws an error" do
      before { expect(Excon).to receive(:get).with(any_args).and_raise(Excon::Errors::SocketError.new(RuntimeError.new())) }

      it "should return false" do
        Armada::Container.healthy?("foo-01", "/metrics/healthcheck", 2181).should be_false
      end
    end
  end


end