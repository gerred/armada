module Armada
  class Image

    attr_reader :id, :image, :name, :tag
    #do not use this method directly, instead call create
    def initialize(options, docker_connection)
      @name              = options[:image]
      @tag               = options[:tag]
      @pull              = options[:pull]
      @docker_connection = docker_connection
      @image             = options[:docker_image]
      @id                = @image.id if @image

      @auth              = generate_auth(options)
    end

    def self.create(options, docker_connection)
      image = Image.get("#{options[:image]}:#{options[:tag]}", docker_connection.connection)
      options[:docker_image] = image
      options[:id] = image.id if image
      Image.new(options, docker_connection)
    end

    def valid?
      return @id && @image
    end

    def pull
      if @pull
        begin
          info "Pulling image [#{@name}] with tag [#{@tag}]"
          @image = ::Docker::Image.create({:fromImage => @name, :tag => @tag}, @auth, @docker_connection.connection)
          @id = @image.id
        rescue Exception => e
          warn "An error occurred while trying to pull image [#{@name}] with tag [#{@tag}] -- #{e.message}"
        end
      else
        info "Not pulling image [#{@name}] with tag [#{@tag}] because `--no-pull` was specified."
        raise "The image id is not set, you cannot proceed with the deploy until a valid image is found -- [#{@name}:#{@tag}]" unless valid?
      end
    end

    def self.get(id, connection)
      ::Docker::Image.get(id, {}, connection)
    end

    def generate_auth(options)
      if options[:dockercfg]
        dockercfg = options[:dockercfg].for_image @name
      else
        dockercfg = Armada::Docker::Credentials.dummy
      end

      username = options.fetch(:username, dockercfg.username)
      password = options.fetch(:password, dockercfg.password)
      email    = options.fetch(:email,    dockercfg.email)

      return { :username => username, :password => password, :email => email } if username && password
    end

    def info(message)
      Armada.ui.info "#{@docker_connection.host} -- #{message}"
    end

    def warn(message)
      Armada.ui.warn "#{@docker_connection.host} -- #{message}"
    end

    def error(message)
      Armada.ui.error "#{@docker_connection.host} -- #{message}"
    end
  end
end

