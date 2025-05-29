# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'cookstyle'
require 'rubocop/rake_task'
require 'kitchen/rake_tasks'

# Style tests - Use Cookstyle for all Ruby/Chef style checks
desc 'Run Cookstyle style checks'
RuboCop::RakeTask.new(:style) do |task|
  task.options << '--display-cop-names'
end

# Rspec and ChefSpec
desc 'Run ChefSpec examples'
RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/**/*_spec.rb'
end

# Kitchen testing
begin
  Kitchen::RakeTasks.new
rescue Kitchen::UserError => e
  puts ">>> Ignoring Kitchen error: #{e}"
end

# Integration testing, including Test Kitchen
namespace :integration do
  desc 'Run Test Kitchen with Vagrant'
  task :vagrant do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.each do |instance|
      instance.test(:always)
    end
  end

  desc 'Run Test Kitchen with Docker'
  task :docker do
    ENV['KITCHEN_LOCAL_YAML'] = '.kitchen.dokken.yml'
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.each do |instance|
      instance.test(:always)
    end
  end
end

# Default
task default: %w(style spec)
