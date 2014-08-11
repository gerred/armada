Dir[File.join(File.dirname(__FILE__), 'armada', '*')].each do |file|
  require file
end

module armada; end
