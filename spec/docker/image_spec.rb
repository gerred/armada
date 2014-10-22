require 'spec_helper'

describe Armada::Image do
  let(:image_id) { "123456789abc123" }
  let(:image_name) { "quay.io/someorg/someimage" }
  let(:tag) { "latest" }
  let(:pull) { true }
  let(:credentials) {
    Armada::Docker::Credentials.new image_name, 'username', 'password', 'email'
  }
  let(:dockercfg) {
    Armada::Docker::Config.new [credentials]
  }
  let(:options) {{
    :image => image_name,
    :tag   => tag,
    :pull  => pull
  }}

  let(:docker_host) { Armada::Host.create("foo-01:4243") }
  let(:docker_connection) { ::Docker::Connection.new("http://foo-01", {}) }
  let(:armada_image) { Armada::Image.new(docker_host, options) }
  let(:docker_image) { ::Docker::Image.new(docker_connection, "id" => image_id) }

  describe "#pull" do
    context "when pull is false" do
      let(:pull) { false }

      it "should not call Docker::Image.create" do
        options.merge!({
          :docker_image => docker_image,
          :id           => image_id
        })
        expect(Docker::Image).not_to receive(:create)
        armada_image.pull

        expect(armada_image.id).to be(image_id)
        expect(armada_image.image).to be(docker_image)
      end

      it { expect { armada_image.pull }.to raise_error }
    end

    context "when pull is true" do
      it "should call Docker::Image.create" do
        expect(::Docker::Image).to receive(:create).and_return(docker_image)
        armada_image.pull
      end
    end
  end

  describe '#generate_auth' do
    context 'with auth and dockercfg' do
      let(:my_options) {
        options.merge({
          username: 'foobar',
          password: 'herpderp',
          dockercfg: dockercfg
        })
      }

      let (:image) { Armada::Image.new(docker_host, my_options) }

      it "should use username and password from options" do
        expect(image.auth[:username]).to be(my_options[:username])
        expect(image.auth[:password]).to be(my_options[:password])
      end
    end

    context 'with no auth and dockercfg' do
      let(:my_options) {
        options.merge({
          dockercfg: dockercfg
        })
      }

      let (:image) { Armada::Image.new(docker_host, my_options) }

      it "should use username and password from dockercfg" do
        expect(image.auth).not_to be_nil
        expect(image.auth[:username]).to be(credentials.username)
        expect(image.auth[:password]).to be(credentials.password)
      end
    end

    context 'with auth and no dockercfg' do
      let(:my_options) {
        options.merge({
          username: 'foobar',
          password: 'herpderp'
        })
      }

      let (:image) { Armada::Image.new(docker_host, my_options) }

      it "should use username and password from options" do
        expect(image.auth[:username]).to be(my_options[:username])
        expect(image.auth[:password]).to be(my_options[:password])
      end
    end

    context 'with no auth and no dockercfg' do
      let (:image) { Armada::Image.new(docker_host, options)}

      it "should have no auth credentials" do
        expect(image.auth).to be_nil
      end
    end
  end
end
