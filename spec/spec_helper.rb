$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each {|f| require f}

require 'armada'
require 'active_support/all'
