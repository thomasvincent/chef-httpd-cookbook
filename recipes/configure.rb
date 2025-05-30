# frozen_string_literal: true

#
# Cookbook:: httpd
# Recipe:: configure
#
# Copyright:: 2023-2025, Thomas Vincent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create main configuration
httpd_config 'main' do
  content <<~CONFIG
    # Generated by Chef
    # Local modifications will be overwritten

    ServerRoot "#{node['httpd']['root_dir']}"
    Timeout #{node['httpd']['config']['timeout']}
    KeepAlive #{node['httpd']['config']['keep_alive']}
    MaxKeepAliveRequests #{node['httpd']['config']['keep_alive_requests']}
    KeepAliveTimeout #{node['httpd']['config']['keep_alive_timeout']}

    # Log configuration
    LogLevel #{node['httpd']['config']['log_level']}
  CONFIG
  action :create
end

# Configure MPM
httpd_config 'mpm' do
  source 'mpm.conf.erb'
  variables(
    mpm: node['httpd']['mpm'],
    server_limit: node['httpd']['performance']['server_limit'],
    max_clients: node['httpd']['performance']['max_clients'],
    max_connections_per_child: node['httpd']['performance']['max_connections_per_child'],
    max_request_workers: node['httpd']['performance']['max_request_workers'],
    start_servers: node['httpd']['performance']['start_servers'],
    min_spare_threads: node['httpd']['performance']['min_spare_threads'],
    max_spare_threads: node['httpd']['performance']['max_spare_threads'],
    thread_limit: node['httpd']['performance']['thread_limit'],
    threads_per_child: node['httpd']['performance']['threads_per_child'],
    prefork_start_servers: node['httpd']['performance']['prefork']['start_servers'],
    prefork_min_spare_servers: node['httpd']['performance']['prefork']['min_spare_servers'],
    prefork_max_spare_servers: node['httpd']['performance']['prefork']['max_spare_servers'],
    prefork_server_limit: node['httpd']['performance']['prefork']['server_limit'],
    prefork_max_clients: node['httpd']['performance']['prefork']['max_clients'],
    prefork_max_requests_per_child: node['httpd']['performance']['prefork']['max_requests_per_child'],
    worker_start_servers: node['httpd']['performance']['worker']['start_servers'],
    worker_min_spare_threads: node['httpd']['performance']['worker']['min_spare_threads'],
    worker_max_spare_threads: node['httpd']['performance']['worker']['max_spare_threads'],
    worker_thread_limit: node['httpd']['performance']['worker']['thread_limit'],
    worker_threads_per_child: node['httpd']['performance']['worker']['threads_per_child'],
    worker_server_limit: node['httpd']['performance']['worker']['server_limit']
  )
  action :create
end

# Security configuration
httpd_config 'security' do
  source 'security.conf.erb'
  variables(
    server_tokens: node['httpd']['security']['server_tokens'],
    server_signature: node['httpd']['security']['server_signature'],
    trace_enable: node['httpd']['security']['trace_enable'],
    clickjacking_protection: node['httpd']['security']['clickjacking_protection'],
    xss_protection: node['httpd']['security']['xss_protection'],
    mime_sniffing_protection: node['httpd']['security']['mime_sniffing_protection'],
    content_security_policy: node['httpd']['security']['content_security_policy']
  )
  action :create
end

# Configure logging
httpd_config 'logging' do
  content <<~CONFIG
    # Generated by Chef
    # Local modifications will be overwritten

    ErrorLog "#{node['httpd']['error_log']}"
    LogLevel #{node['httpd']['config']['log_level']}

    <IfModule log_config_module>
        # Define log formats
        LogFormat "#{node['httpd']['config']['log_format']['combined']}" combined
        LogFormat "#{node['httpd']['config']['log_format']['common']}" common
        LogFormat "#{node['httpd']['config']['log_format']['json']}" json

        # Set up access logging
        CustomLog "#{node['httpd']['access_log']}" combined
    </IfModule>
  CONFIG
  action :create
end

# Configure default directories
httpd_config 'directories' do
  content <<~CONFIG
    # Generated by Chef
    # Local modifications will be overwritten

    # Default directory settings
    #{node['httpd']['default_directories'].map do |dir|
      <<~DIR
        <Directory "#{dir['path']}">
            Options #{dir['options']}
            AllowOverride #{dir['allow_override']}
            Require #{dir['require']}
        </Directory>
      DIR
    end.join("\n")}
  CONFIG
  action :create
end

# Configure health check if enabled
if node['httpd']['health_check']['enabled']
  httpd_config 'health-check' do
    source 'health-check.conf.erb'
    variables(
      health_check_path: node['httpd']['health_check']['path'],
      health_check_content: node['httpd']['health_check']['content']
    )
    action :create
  end
end

# Configure monitoring if enabled
if node['httpd']['monitoring']['enabled']
  httpd_config 'monitoring' do
    source 'monitoring.conf.erb'
    variables(
      status_path: node['httpd']['monitoring']['status_path'],
      restricted_access: node['httpd']['monitoring']['restricted_access'],
      allowed_ips: node['httpd']['monitoring']['allowed_ips']
    )
    action :create
  end
end

# Configure SSL if enabled
if node['httpd']['ssl']['enabled']
  httpd_config 'ssl' do
    source 'ssl.conf.erb'
    variables(
      ssl_port: node['httpd']['ssl']['port'],
      ssl_protocol: node['httpd']['ssl']['protocol'],
      ssl_cipher_suite: node['httpd']['ssl']['cipher_suite'],
      ssl_honor_cipher_order: node['httpd']['ssl']['honor_cipher_order'],
      ssl_session_tickets: node['httpd']['ssl']['session_tickets'],
      ssl_session_timeout: node['httpd']['ssl']['session_timeout'],
      ssl_session_cache: node['httpd']['ssl']['session_cache'],
      ssl_certificate: node['httpd']['ssl']['certificate'],
      ssl_certificate_key: node['httpd']['ssl']['certificate_key'],
      ssl_certificate_chain: node['httpd']['ssl']['certificate_chain'],
      hsts: node['httpd']['ssl']['hsts'],
      hsts_max_age: node['httpd']['ssl']['hsts_max_age'],
      hsts_include_subdomains: node['httpd']['ssl']['hsts_include_subdomains'],
      hsts_preload: node['httpd']['ssl']['hsts_preload'],
      ocsp_stapling: node['httpd']['ssl']['ocsp_stapling']
    )
    action :create
  end
end

# Configure host-based access control
if platform_family?('debian')
  httpd_config 'security' do
    content <<~CONFIG
      # Generated by Chef
      # Local modifications will be overwritten

      # Host-based access control
      <Directory />
          Options none
          AllowOverride none
          Require all denied
      </Directory>

      <Directory "#{node['httpd']['default_vhost']['document_root']}">
          Options #{node['httpd']['default_vhost']['directory_options']}
          AllowOverride #{node['httpd']['default_vhost']['allow_override']}
          Require all granted
      </Directory>
    CONFIG
    action :create
  end
end

# Configure MIME types
httpd_config 'mime' do
  content <<~CONFIG
    # Generated by Chef
    # Local modifications will be overwritten

    # Setting up MIME types
    TypesConfig #{node['httpd']['root_dir']}/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType application/x-bzip2 .bz2
    AddType text/html .shtml
    AddType text/cache-manifest .appcache .manifest
    AddType text/x-component .htc
    AddType application/x-chrome-extension .crx
    AddType application/x-xpinstall .xpi
    AddType application/octet-stream .safariextz
    AddType text/x-vcard .vcf
    AddType application/x-httpd-php .php
    AddType application/json .json
    AddType application/ld+json .jsonld
    AddType application/xml .xml
  CONFIG
  action :create
end

log 'Apache HTTP Server configuration completed' do
  level :info
end
