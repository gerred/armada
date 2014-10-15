module Armada
  class Configs
    attr_reader :configs
    def initialize(configs)
      @configs = configs
    end

    def for_url(url)
      @configs.each do |config|
        return config if url.start_with? config.url
      end
    end

    def self.load(path)
      abs_path = File.expand_path path
      configs = []

      if File.readable? abs_path
        json_hash = JSON.parse(IO.read(abs_path))
        json_hash.each do |url, cred|
          configs.append cred.merge url: url
        end
      end

      Configs.new configs
    end
  end
end
