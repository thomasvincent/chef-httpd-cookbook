# frozen_string_literal: true

# Declare the service so notification targets resolve
service node['httpd']['service_name'] do
  action :nothing
end

httpd_install 'default' do
  action :install
end
