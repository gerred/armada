$: << File.expand_path("lib")
require 'geminabox/rake'
Geminabox::Rake.install host: 'http://gems.f4tech.com'

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.rspec_opts = %w[--color --format=documentation]
    t.pattern = "spec/**/*_spec.rb"
  end

  task :default => [:spec]
rescue LoadError
  # don't generate Rspec tasks if we don't have it installed
end
