$: << File.expand_path("lib")
require 'bundler/gem_tasks'

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

# Let bundler's release task do its job, minus the push to Rubygems,
# and after it completes, use "gem inabox" to publish the gem to our
# internal gem server.
Rake::Task["release"].enhance do
  gem_server_url = 'http://gems.f4tech.com'
  spec = Gem::Specification::load(Dir.glob("*.gemspec").first)
  sh "gem inabox pkg/#{spec.name}-#{spec.version}.gem --host #{gem_server_url}"
end

