require 'armada/docker_registry'
require 'armada/api'

namespace :list do
  task :running_container_tags do
    output = []
    on_each_docker_host do |host|
      tags = []
      Docker::Container.all({}, host).each do |container|
        image = Armada::Api.get_image_by_container(host, container)
        tags << Armada::Api.get_all_tags_for_image(host, image) if Armada::Api.tag_matches_image_name?(fetch(:image), image.info["RepoTags"])
      end
      output << {server: URI.parse(host.url).host, tags: tags} if tags
    end


    $stderr.puts "\n\nCurrent #{current_environment} tags for image - #{fetch(:image)}:\n\n"
    output.each do |info|
      if info && !info[:tags].empty?
        $stderr.puts "#{'%-20s' % info[:server]}: #{info[:tags].join(', ')}"
      else
        $stderr.puts "#{'%-20s' % info[:server]}: NO TAGS!"
      end
    end

    $stderr.puts "\nAll tags for this image: #{output.map { |t| t[:tags] }.flatten.uniq.join(', ')}"
  end


  task :running_containers do
    on_each_docker_host do |host|
      Docker::Container.all({}, host).each do |running_container|
        puts "#{host.url} : #{running_container.info['Image']} -- #{running_container.json['Name']} (#{running_container.json['Id'][0..7]})"
      end
    end
  end
end
