$: << File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'armada'
require 'webmock/rspec'

RSpec.configure do |config|
  config.mock_with :rspec
  config.color                             = true
  config.formatter                         = :documentation
  config.tty                               = true
end
