# frozen_string_literal: true

# Test recipe for httpd_vhost resource

# Declare the service so notification targets resolve
service node['httpd']['service_name'] do
  action :nothing
end

# Basic virtual host
httpd_vhost 'example.com' do
  domain 'example.com'
  document_root '/var/www/example.com'
  aliases ['www.example.com']
  priority 10
  enabled true
  action :create
end

# SSL-enabled virtual host
httpd_vhost 'secure.example.com' do
  domain 'secure.example.com'
  document_root '/var/www/secure.example.com'
  ssl_enabled true
  ssl_cert '/etc/ssl/certs/secure.example.com.pem'
  ssl_key '/etc/ssl/private/secure.example.com.key'
  priority 10
  enabled true
  action :create
end

# Disabled virtual host
httpd_vhost 'disabled.com' do
  domain 'disabled.com'
  document_root '/var/www/disabled.com'
  priority 20
  enabled false
  action :create
end
