module Armada
  class Image

    attr_reader :id, :image, :name, :tag, :auth
    #do not use this method directly, instead call create
    def initialize(docker_host, options)
      @name        = options[:image]
      @tag         = options[:tag]
      @pull        = options[:pull]
      @docker_host = docker_host
      @image       = options[:docker_image]
      @id          = @image.id if @image
      @auth        = generate_auth(options)
    end

    def valid?
      return @id && @image
    end

    def pull
      if @pull
        begin
          info "Pulling image [#{@name}] with tag [#{@tag}]"
          @image = ::Docker::Image.create({:fromImage => @name, :tag => @tag}, @auth, @docker_host.connection)
          @id = @image.id
        rescue Exception => e
          warn "An error occurred while trying to pull image [#{@name}] with tag [#{@tag}] -- #{e.message}"
        end
      else
        info "Not pulling image [#{@name}] with tag [#{@tag}] because `--no-pull` was specified."
        raise "The image id is not set, you cannot proceed with the deploy until a valid image is found -- [#{@name}:#{@tag}]" unless valid?
      end
    end

    def extract_credentials(options)
      options_credentials = options.select { |k, v| [:username, :password, :email].include? k }
      unless options_credentials.empty?
        return options_credentials
      else
        dockercfg = options[:dockercfg].for_image @name if options[:dockercfg]
        if dockercfg.nil?
          return {}
        else
          return {
            :username => dockercfg.username,
            :password => dockercfg.password,
            :email    => dockercfg.email
          }
        end
      end
    end

    def valid_credentials?(m)
      [:username, :password].each do |k|
        unless m.include? k
          return false
        end
      end

      return true
    end

    def generate_auth(options)
      credentials = extract_credentials(options)

      if valid_credentials? credentials
        return credentials
      else
        return nil
      end
    end

    def info(message)
      Armada.ui.info "#{@docker_host.host} -- #{message}"
    end

    def warn(message)
      Armada.ui.warn "#{@docker_host.host} -- #{message}"
    end

    def error(message)
      Armada.ui.error "#{@docker_host.host} -- #{message}"
    end
  end
end

