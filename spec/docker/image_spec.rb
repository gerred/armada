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

  let(:someimage_history) {
    {
          "Created" => 1411767440,
        "CreatedBy" => "/bin/sh -c #(nop) CMD [./start-bagboy.sh]",
               "Id" => "123456789abc123",
             "Size" => 0,
             "Tags" => ["quay.io/someorg/someimage:latest"]
    }
  }
  let(:fooimage_history) {
    {
          "Created" => 1411767439,
        "CreatedBy" => "/bin/sh -c #(nop) EXPOSE map[3110/tcp:{}]",
               "Id" => "not-123456789abc123",
             "Size" => 0,
             "Tags" => nil
    }
  }
  let(:history) {[someimage_history, fooimage_history]}

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
        expect(Docker::Image).to receive(:create).and_return(docker_image)
        armada_image.pull
      end
    end
  end

  describe "#first_by_tag" do
    context "when history and tag are given" do
      it { Armada::Image.first_by_tag(history, "#{image_name}:#{tag}").should be(someimage_history) }
    end

    context "when tag does not exist" do
      it { expect { Armada::Image.first_by_tag(history, "#{image_name}:someothertag") }.to raise_error }
    end

    context "when the tag is nil" do
      it { expect { Armada::Image.first_by_tag(history, nil) }.to raise_error(/Image tag/) }
    end
  end

end
