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

  let(:connection) { Docker::Connection.new("http://foo-01", {}) }
  let(:armada_image) { Armada::Image.new(options, connection) }
  let(:docker_image) { Docker::Image.new(connection, "id" => image_id) }

  describe "#pull" do
    context "when no_pull is true" do
      let(:no_pull) { true }

      it "should not call Docker::Image.create" do
        expect(Docker::Image).not_to receive(:create)
        armada_image.pull
      end
    end

    context "when no_pull is false" do
      it "should call Docker::Image.create" do
        expect(Docker::Image).to receive(:create).and_return(docker_image)
        armada_image.pull
      end
    end
  end

end
