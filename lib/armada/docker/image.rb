module Armada
  class Image

    attr_reader :id, :image, :name, :tag
    def initialize(options, connection)
      @id         = nil
      @image      = nil
      @name       = options[:image]
      @tag        = options[:tag]
      @no_pull    = options[:no_pull]
      @auth       = auth(options[:username], options[:password], options[:email])
      @connection = connection
    end

    def pull
      unless @no_pull
        info "Pulling image [#{@name}] with tag #{@tag}"
        begin
          @image = Docker::Image.create({:fromImage => @name, :tag => @tag}, @auth, @connection)
          @id = image.id
        rescue Exception => e
          error "#{e.inspect} \n #{e.backtrace.join("\n")}"
        end
      end
    end

    def auth(username, password, email = "")
      return { :username => username, :password => password, :email => email } if username && password
      return {}
    end

    def info(message)
      Armada.ui.info "#{URI.parse(@connection.url).host} -- #{message}"
    end

    def error(message)
      Armada.ui.error "#{URI.parse(@connection.url).host} -- #{message}"
    end

  end
end
