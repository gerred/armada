require 'spec_helper'

describe Armada::Connection::Docker do
  let(:connection) { described_class.new('localhost:1234').connection }

  context 'when no certificate path is set' do
    before(:each) { ENV['DOCKER_CERT_PATH'] = nil }

    context 'scheme' do
      subject { connection.url }

      it { should start_with 'http://' }
    end

    context 'connection options' do
      subject { connection.options }

      it { should_not include(:client_cert, :client_key, :ssl_ca_file, :ssl_verify_peer) }
    end
  end

  context 'when docker tls verify is set' do
  end

  context 'when certificate path is set' do
    before(:each) { ENV['DOCKER_CERT_PATH'] = '/some/cert/path' }

    context 'scheme' do
      subject { connection.url }

      it { should start_with 'https://' }
    end

    context 'connection options' do
      subject { connection.options }

      it { should include(:client_cert, :client_key, :ssl_ca_file, :ssl_verify_peer) }
      its([:ssl_verify_peer]) { should be_false }
    end

    context 'disable TLS verify' do
      before(:each) { ENV['DOCKER_TLS_VERIFY'] = '0'}
      subject { connection.options }

      it { should include(:client_cert, :client_key, :ssl_ca_file, :ssl_verify_peer) }
      its([:ssl_verify_peer]) { should be_false }
    end

    context 'enable TLS verify' do
      before(:each) { ENV['DOCKER_TLS_VERIFY'] = '1'}
      subject { connection.options }

      it { should include(:client_cert, :client_key, :ssl_ca_file, :ssl_verify_peer) }
      its([:ssl_verify_peer]) { should be_true }
    end
  end

end
