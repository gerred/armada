require 'spec_helper'

describe Armada::Connection::HealthCheck do

  describe ".healthy?" do
    context "when the container health check passes" do
      subject { Armada::Connection::HealthCheck.new("foo-01", 2181) }
      let(:mock_ok_status)  { double('http_status_ok').tap { |s| s.stub(status: 200) } }
      before { expect(Excon).to receive(:get).with(any_args).and_return(mock_ok_status) }

      it "should return true" do
        subject.healthy?.should be_true
      end
    end

    context "when the container health check fails" do
      subject { Armada::Connection::HealthCheck.new("foo-01", 2181) }
      let(:mock_bad_status)  { double('http_status_ok').tap { |s| s.stub(status: 500) } }
      before { expect(Excon).to receive(:get).with(any_args).and_return(mock_bad_status) }

      it "should return false" do
        subject.healthy?.should be_false
      end
    end

    context "when the container health check throws an error" do
      subject { Armada::Connection::HealthCheck.new("foo-01", 2181) }
      before { expect(Excon).to receive(:get).with(any_args).and_raise(Excon::Errors::SocketError.new(RuntimeError.new())) }

      it "should return false" do
        subject.healthy?.should be_false
      end
    end
  end

end
