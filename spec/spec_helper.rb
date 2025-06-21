# frozen_string_literal: true

require 'chefspec'
require 'simplecov'

# Start SimpleCov
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_group 'Libraries', 'libraries'
  add_group 'Resources', 'resources'
  add_group 'Recipes', 'recipes'
end

RSpec.configure do |config|
  # Specify the Chef log_level (default: :warn)
  config.log_level = :error

  # Specify the operating platform to mock Ohai data from (default: nil)
  config.platform = 'ubuntu'

  # Specify the operating version to mock Ohai data from (default: nil)
  config.version = '20.04'

  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :json, :junit, :progress, :documentation

  # Include ChefSpec::API in the RSpec context
  config.include ChefSpec::API

  # Run cleanup after each example
  config.after(:each) do
    ChefSpec::Coverage.report! if defined?(ChefSpec::Coverage)
  end
end

# Helper method for stubbing resources
def stub_resources
  allow_any_instance_of(Chef::ResourceCollection).to receive(:find).and_call_original
  allow_any_instance_of(Chef::ResourceCollection).to receive(:find).with('template[/etc/httpd/conf/httpd.conf]').and_return(
    Chef::Resource::Template.new('/etc/httpd/conf/httpd.conf', run_context).tap do |r|
      r.source 'httpd.conf.erb'
      r.cookbook 'httpd'
    end
  )
end
