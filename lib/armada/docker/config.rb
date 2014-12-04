require 'base64'

module Armada
  module Docker
    class Config
      attr_reader :configs
      def initialize(configs)
        @configs = configs
      end

      def for_image(url)
        @configs.each do |config|        
          config_url = URI.parse(config.url).host || config.url
          if url.start_with? config_url
            return config
          end
        end
        nil
      end

      def self.load(path)
        abs_path = File.expand_path path
        configs = []

        if File.readable? abs_path
          json_hash = JSON.parse(IO.read(abs_path))
          Armada.ui.info "Loading dockercfg from: #{abs_path}"
          json_hash.each do |url, obj|
            configs.push Credentials.parse(url, obj)
          end
        end

        Config.new configs
      end
    end

    class Credentials
      attr_reader :url, :username, :password, :email
      def initialize(url, username, password, email)
        @username = username
        @password = password
        @email = email
        @url = url
      end

      def self.parse(url, obj)
        username, password = Base64.decode64(obj["auth"]).split(':', 2)
        return self.new url, username, password, obj["email"]
      end

      def self.dummy()
        self.new '', nil, nil, ''
      end
    end
  end
end
