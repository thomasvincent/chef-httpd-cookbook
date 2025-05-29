# frozen_string_literal: true

source 'https://rubygems.org'

# Specify Ruby version for consistency (allow 3.1.x or higher)
ruby '>= 3.1.0'

group :development do
  gem 'ruby-lsp', '~> 0.14.0'
  gem 'debug', '~> 1.9'
  gem 'chef', '~> 18.0'
  gem 'chef-cli', '~> 5.6'
  gem 'chefspec', '~> 9.3', '>= 9.3.3'
  gem 'cookstyle', '~> 7.32'
  gem 'rspec', '~> 3.11.0'
end

group :test do
  gem 'inspec-bin', '>= 5.21'
  gem 'kitchen-dokken', '~> 2.20'
  gem 'kitchen-inspec', '~> 2.6'
  gem 'rspec-its', '~> 1.3'
  gem 'rspec_junit_formatter', '~> 0.6'
  gem 'simplecov', '~> 0.22'
  gem 'simplecov-console', '~> 0.9'
  gem 'test-kitchen', '~> 3.5'
end

group :docs do
  gem 'github-markup'
  gem 'redcarpet'
  gem 'yard'
end
