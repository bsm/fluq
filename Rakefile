require 'rake'

require 'rspec/mocks/version'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'yard'
YARD::Rake::YardocTask.new

desc 'Default: run specs.'
task :default => :spec
