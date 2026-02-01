# frozen_string_literal: true

# Test recipe for httpd_module resource

# Declare the service so notification targets resolve
service node['httpd']['service_name'] do
  action :nothing
end

# Enable SSL module
httpd_module 'ssl' do
  action :enable
end

# Disable rewrite module
httpd_module 'rewrite' do
  action :disable
end

# Enable status module with configuration
httpd_module 'status' do
  configuration <<~CONF
    <Location "/server-status">
      SetHandler server-status
      Require local
    </Location>
  CONF
  action :enable
end
