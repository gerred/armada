require 'spec_helper'

describe Armada::Image do
  let(:image_id) { "123456789abc123" }
  let(:image_name) { "quay.io/someorg/someimage" }
  let(:tag) { "latest" }
  let(:no_pull) { false }
  let(:options) {{
    :image          => image_name,
    :tag            => tag,
    :no_pull        => no_pull
  }}

  let(:connection) { Armada::Connection::Docker.new("foo-01:4243") }
  let(:docker_connection) { ::Docker::Connection.new("http://foo-01", {}) }
  let(:armada_image) { Armada::Image.new(options, connection) }
  let(:docker_image) { ::Docker::Image.new(docker_connection, "id" => image_id) }

  describe "#pull" do
    context "when no_pull is true" do
      let(:no_pull) { true }

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

    context "when no_pull is false" do
      it "should call Docker::Image.create" do
        expect(::Docker::Image).to receive(:create).and_return(docker_image)
        armada_image.pull
      end
    end
  end


end
