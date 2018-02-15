require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'yard'
require 'yard/rake/yardoc_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

FILES = ['lib/**/*.rb']
OPTIONS = ['--debug', '--verbose']

YARD::Rake::YardocTask.new do |t|
  t.files   = FILES
  t.options = []
  t.options << OPTIONS if $trace
end
