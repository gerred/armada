module Armada
  module Clean
    class Images
      def initialize(options)
        @hosts   = options[:hosts]
        @force   = options[:force]
        @noprune = !options[:prune]
        @options = options
      end

      def run
        Armada.ui.info "******* DRY RUN *******" unless @force
        @hosts.each_in_parallel do |host|
          docker_host = Armada::Host.create(host, @options)
          docker_host.get_all_images.each do |image|
            if image.info["RepoTags"].include?("<none>:<none>") && !image.info["ParentId"]
              begin
                Armada.ui.info "#{docker_host.host} -- #{image.id[0..11]} is an abandoned image and will be removed"
                image.remove({:force => true, :noprune => @noprune}) if @force
              rescue Exception => e
                Armada.ui.error "#{docker_host.host} -- unable to remove image #{image.id[0..11]} because of the following error - #{e.message}"
              end
            end
          end
        end
      end
    end
  end
end
