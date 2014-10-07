module Armada
  class Image

    attr_reader :id, :image, :name, :tag
    #do not use this method directly, instead call create
    def initialize(options, connection)
      @name       = options[:image]
      @tag        = options[:tag]
      @no_pull    = options[:no_pull]
      @auth       = auth(options[:username], options[:password], options[:email])
      @connection = connection
      @image      = options[:docker_image]
      @id         = @image.id if @image
    end

    def self.create(options, connection)
      image = Image.find_by_name_and_tag(options[:image], options[:tag], connection)
      options[:docker_image] = image
      options[:id] = image.id if image
      Image.new(options, connection)
    end

    def valid?
      return @id && @image
    end

    def pull
      unless @no_pull
        info "Pulling image [#{@name}] with tag [#{@tag}]"
        begin
          @image = Docker::Image.create({:fromImage => @name, :tag => @tag}, @auth, @connection)
          @id = @image.id
        rescue Exception => e
          error e.message
          exit(1)
        end
      else
        info "Not pulling image [#{@name}] with tag [#{tag}] because `--no-pull` was specified."
        raise "The image id is not set, you cannot proceed with the deploy until a valid image is found -- [#{@name}:#{@tag}]" unless valid?
      end
    end

    #repo_tag is the combination of image name and tag - quay.io/someorg/someimage:latest
    def self.first_by_tag(history, repo_tag)
      raise "Image tag must be supplied" unless repo_tag

      idx = history.find_index { |item| item["Tags"].include?("#{repo_tag}") if item["Tags"] }
      raise "Unable to find image [#{repo_tag}] in the history." unless idx
      return history.at(idx)
    end

    def self.history(name, connection)
      body = connection.get("/images/#{URI.encode(name)}/history")
      return Docker::Util.parse_json(body)
    end

    def self.find_by_name_and_tag(name, tag, connection)
      begin
        history = Image.history(name, connection)
        history_image = Image.first_by_tag(history, "#{name}:#{tag}")
        return Image.get(history_image["Id"], connection)
      rescue Exception => e
        return nil
      end
    end

    def self.get(id, connection)
      Docker::Image.get(id, {}, connection)
    end

    def auth(username, password, email = "")
      return { :username => username, :password => password, :email => email } if username && password
    end

    def info(message)
      Armada.ui.info "#{URI.parse(@connection.url).host} -- #{message}"
    end

    def error(message)
      Armada.ui.error "#{URI.parse(@connection.url).host} -- #{message}"
    end

  end
end

