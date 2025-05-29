# frozen_string_literal: true

source 'https://rubygems.org'

# Specify Ruby version for consistency (allow 3.1.x or higher)
ruby '>= 3.1.0'

group :development do
  gem 'ruby-lsp', '~> 0.23.23'
  gem 'debug', '~> 1.9'
  gem 'chef', '~> 19.0'
  gem 'chef-cli', '~> 5.6'
  gem 'chefspec', '~> 9.3', '>= 9.3.3'
  gem 'cookstyle', '~> 8.1'
  gem 'rspec', '~> 3.11.0'
end

group :test do
  gem 'inspec-bin', '>= 7.0'
  gem 'kitchen-docker', '~> 3.0'
  gem 'kitchen-inspec', '~> 3.0'
  gem 'rspec-its', '~> 1.3'
  gem 'rspec_junit_formatter', '~> 0.6'
  gem 'simplecov', '~> 0.22'
  gem 'simplecov-console', '~> 0.9'
  gem 'test-kitchen', '~> 3.7'
end

group :docs do
  gem 'github-markup'
  gem 'redcarpet'
  gem 'yard'
end
