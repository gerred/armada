require 'spec_helper'

describe Armada::Connection::RemoteHost do

  describe "#new" do
    context "when given host and port as 1 string" do
      subject { Armada::Connection::RemoteHost.new("foo:4243") }
      it { expect(subject.host).to eq "foo" }
      it { expect(subject.port).to eq "4243" }
    end

    context "when host and port are given as seperate params" do
      subject { Armada::Connection::RemoteHost.new("foo", "4243") }
      it { expect(subject.host).to eq "foo" }
      it { expect(subject.port).to eq "4243" }
    end
  end
  
end