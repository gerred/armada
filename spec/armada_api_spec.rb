# require 'spec_helper'

# # We should add a bunch of tests here on Armada::Api
# describe Armada::Api do

#   describe '#get_container_by_name' do
#     let(:connection) { Docker::Connection.new("http://bld-docker-01:4243", {}) }
#     context "nonexistant container" do
#       it { expect(Armada::Api.get_container_by_name(connection, 'nonexistant_container_name')).to be_nil }
#     end
#   end

#   describe '#create_container_config' do
#     let(:host) { "http://foo.docker:4243" }
#     let(:opts) { { :port_bindings => {'8080' => ''}, :image_id => 'baz' } }
#     it 'should return a reasonable container config' do
#       container_config = Armada::Api.create_container_config(host, opts)
#       expect(container_config['ExposedPorts']['8080']).to be_a(Hash)
#     end
#   end

# end
