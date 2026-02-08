# frozen_string_literal: true

source 'https://rubygems.org'

gem 'chef', '~> 18.0'
gem 'chef-cli', '~> 5.6'
gem 'chefspec', '~> 9.3'
gem 'cookstyle', '~> 8.1'

# Pin psych to avoid compilation issues with Ruby 3.2+
gem 'psych', '< 5'

group :development do
  gem 'rake', '~> 13.0'
end

group :test do
  # Use inspec-core (not inspec) to avoid commercial chef-licensing requirement in InSpec 7+
  gem 'inspec-core', '~> 6.0'
  gem 'kitchen-dokken', '~> 2.20'
  # 3.1+ supports test-kitchen 4.x and inspec-core 6.x/7.x
  gem 'kitchen-inspec', '~> 3.1'
  gem 'test-kitchen', '>= 3.0'
  gem 'simplecov', '~> 0.22'
  gem 'simplecov-console', '~> 0.9'
  gem 'rspec_junit_formatter', '~> 0.6'
end
