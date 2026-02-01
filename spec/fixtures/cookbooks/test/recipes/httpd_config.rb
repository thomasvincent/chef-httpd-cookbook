# frozen_string_literal: true

# Test recipe for httpd_config resource

# Declare the service so notification targets resolve
service node['httpd']['service_name'] do
  action :nothing
end

# Content-based config
httpd_config 'test-config' do
  content "# Test config\nServerName localhost\n"
  action :create
end

# Template-based config
httpd_config 'template-config' do
  source 'security.conf.erb'
  cookbook 'httpd'
  variables(
    server_tokens: 'Prod',
    server_signature: 'Off',
    trace_enable: 'Off',
    clickjacking_protection: true,
    xss_protection: true,
    mime_sniffing_protection: true,
    content_security_policy: "default-src 'self'"
  )
  action :create
end

# Disabled config
httpd_config 'disabled-config' do
  content '# Disabled'
  enable false
  action :create
end
