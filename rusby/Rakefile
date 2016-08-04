require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = [
    '--color',
    '--require',
    'spec_helper'
  ]
end

task :default => :spec
