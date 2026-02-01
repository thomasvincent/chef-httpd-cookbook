# frozen_string_literal: true

#
# Cookbook:: httpd
# Attributes:: default
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

# Installation attributes
default['httpd']['install_method'] = 'package' # 'package' or 'source'
default['httpd']['version'] = '2.4.57'

# Package-specific attributes
case node['platform_family']
when 'rhel', 'fedora', 'amazon'
  default['httpd']['package_name'] = 'httpd'
  default['httpd']['service_name'] = 'httpd'
  default['httpd']['root_dir'] = '/etc/httpd'
  default['httpd']['conf_dir'] = '/etc/httpd/conf'
  default['httpd']['conf_available_dir'] = '/etc/httpd/conf.available'
  default['httpd']['conf_enabled_dir'] = '/etc/httpd/conf.d'
  default['httpd']['user'] = 'apache'
  default['httpd']['group'] = 'apache'
  default['httpd']['binary'] = '/usr/sbin/httpd'
  default['httpd']['icon_dir'] = '/usr/share/httpd/icons'
  default['httpd']['module_dir'] = '/etc/httpd/modules'
  default['httpd']['mod_dir'] = '/etc/httpd/conf.modules.d'
  default['httpd']['includes_dir'] = '/etc/httpd/conf.d'
  default['httpd']['pid_file'] = '/var/run/httpd/httpd.pid'
  default['httpd']['error_log'] = '/var/log/httpd/error_log'
  default['httpd']['access_log'] = '/var/log/httpd/access_log'
  default['httpd']['lib_dir'] = node['kernel']['machine'] =~ /^i[36]86$/ ? '/usr/lib/httpd' : '/usr/lib64/httpd'
  default['httpd']['libexec_dir'] = "#{node['httpd']['lib_dir']}/modules"
  default['httpd']['default_site_enabled'] = false
when 'debian'
  default['httpd']['package_name'] = 'apache2'
  default['httpd']['service_name'] = 'apache2'
  default['httpd']['root_dir'] = '/etc/apache2'
  default['httpd']['conf_dir'] = '/etc/apache2'
  default['httpd']['conf_available_dir'] = '/etc/apache2/conf-available'
  default['httpd']['conf_enabled_dir'] = '/etc/apache2/conf-enabled'
  default['httpd']['user'] = 'www-data'
  default['httpd']['group'] = 'www-data'
  default['httpd']['binary'] = '/usr/sbin/apache2'
  default['httpd']['icon_dir'] = '/usr/share/apache2/icons'
  default['httpd']['module_dir'] = '/usr/lib/apache2/modules'
  default['httpd']['mod_dir'] = '/etc/apache2/mods-available'
  default['httpd']['mod_enabled_dir'] = '/etc/apache2/mods-enabled'
  default['httpd']['includes_dir'] = '/etc/apache2/conf.d'
  default['httpd']['pid_file'] = '/var/run/apache2/apache2.pid'
  default['httpd']['error_log'] = '/var/log/apache2/error.log'
  default['httpd']['access_log'] = '/var/log/apache2/access.log'
  default['httpd']['lib_dir'] = '/usr/lib/apache2'
  default['httpd']['libexec_dir'] = "#{node['httpd']['lib_dir']}/modules"
  default['httpd']['default_site_enabled'] = false
when 'freebsd'
  default['httpd']['package_name'] = 'apache24'
  default['httpd']['service_name'] = 'apache24'
  default['httpd']['root_dir'] = '/usr/local/etc/apache24'
  default['httpd']['conf_dir'] = '/usr/local/etc/apache24'
  default['httpd']['conf_available_dir'] = '/usr/local/etc/apache24/Includes'
  default['httpd']['conf_enabled_dir'] = '/usr/local/etc/apache24/Includes'
  default['httpd']['user'] = 'www'
  default['httpd']['group'] = 'www'
  default['httpd']['binary'] = '/usr/local/sbin/httpd'
  default['httpd']['icon_dir'] = '/usr/local/share/apache24/icons'
  default['httpd']['module_dir'] = '/usr/local/libexec/apache24'
  default['httpd']['mod_dir'] = '/usr/local/etc/apache24/modules.d'
  default['httpd']['includes_dir'] = '/usr/local/etc/apache24/Includes'
  default['httpd']['pid_file'] = '/var/run/httpd.pid'
  default['httpd']['error_log'] = '/var/log/httpd-error.log'
  default['httpd']['access_log'] = '/var/log/httpd-access.log'
  default['httpd']['lib_dir'] = '/usr/local/libexec/apache24'
  default['httpd']['libexec_dir'] = '/usr/local/libexec/apache24'
  default['httpd']['default_site_enabled'] = false
when 'mac_os_x'
  default['httpd']['package_name'] = 'httpd'
  default['httpd']['service_name'] = 'httpd'
  default['httpd']['root_dir'] = '/opt/homebrew/etc/httpd'
  default['httpd']['conf_dir'] = '/opt/homebrew/etc/httpd'
  default['httpd']['conf_available_dir'] = '/opt/homebrew/etc/httpd/extra'
  default['httpd']['conf_enabled_dir'] = '/opt/homebrew/etc/httpd/extra'
  default['httpd']['user'] = '_www'
  default['httpd']['group'] = '_www'
  default['httpd']['binary'] = '/opt/homebrew/bin/httpd'
  default['httpd']['icon_dir'] = '/opt/homebrew/share/httpd/icons'
  default['httpd']['module_dir'] = '/opt/homebrew/lib/httpd/modules'
  default['httpd']['mod_dir'] = '/opt/homebrew/etc/httpd/extra'
  default['httpd']['includes_dir'] = '/opt/homebrew/etc/httpd/extra'
  default['httpd']['pid_file'] = '/opt/homebrew/var/run/httpd/httpd.pid'
  default['httpd']['error_log'] = '/opt/homebrew/var/log/httpd/error_log'
  default['httpd']['access_log'] = '/opt/homebrew/var/log/httpd/access_log'
  default['httpd']['lib_dir'] = '/opt/homebrew/lib/httpd'
  default['httpd']['libexec_dir'] = '/opt/homebrew/lib/httpd/modules'
  default['httpd']['default_site_enabled'] = false
end

# Source installation attributes
default['httpd']['source']['url'] = "https://archive.apache.org/dist/httpd/httpd-#{node['httpd']['version']}.tar.gz"
default['httpd']['source']['checksum'] = nil # Auto-generated
default['httpd']['source']['prefix'] = '/usr/local/apache2'
default['httpd']['source']['configure_options'] = %W(
  --prefix=#{node['httpd']['source']['prefix']}
  --enable-layout=Unix
  --enable-mods-shared=all
  --enable-ssl
  --enable-http2
  --enable-proxy
  --enable-proxy-http
  --enable-proxy-fcgi
  --enable-rewrite
  --enable-deflate
  --with-ssl=/usr
  --with-mpm=event
)
default['httpd']['source']['dependencies'] = case node['platform_family']
                                             when 'rhel', 'fedora', 'amazon'
                                               %w(
                                                 openssl-devel
                                                 pcre-devel
                                                 zlib-devel
                                                 libxml2-devel
                                                 lua-devel
                                                 curl-devel
                                                 nghttp2-devel
                                                 jansson-devel
                                                 brotli-devel
                                                 libnghttp2-devel
                                                 apr-devel
                                                 apr-util-devel
                                               )
                                             when 'debian'
                                               %w(
                                                 libssl-dev
                                                 libpcre3-dev
                                                 zlib1g-dev
                                                 libxml2-dev
                                                 liblua5.3-dev
                                                 libcurl4-openssl-dev
                                                 libnghttp2-dev
                                                 libjansson-dev
                                                 libbrotli-dev
                                                 libapr1-dev
                                                 libaprutil1-dev
                                               )
                                             when 'freebsd'
                                               %w(
                                                 apr
                                                 pcre
                                                 libxml2
                                                 lua54
                                                 curl
                                                 libnghttp2
                                                 jansson
                                               )
                                             when 'mac_os_x'
                                               %w(
                                                 apr
                                                 apr-util
                                                 pcre
                                                 openssl
                                                 libxml2
                                                 nghttp2
                                               )
                                             else
                                               []
                                             end

# Multi-Processing Module configuration
default['httpd']['mpm'] = 'event' # Options: event, worker, prefork

# Performance tuning (auto-adjusted based on system resources)
cpu_count = node['cpu'] ? node['cpu']['total'].to_i : 2
default['httpd']['performance']['max_clients'] = [cpu_count * 150, 256].max
default['httpd']['performance']['max_connections_per_child'] = 0
default['httpd']['performance']['start_servers'] = [cpu_count, 2].max
default['httpd']['performance']['min_spare_threads'] = [cpu_count * 5, 25].min
default['httpd']['performance']['max_spare_threads'] = [cpu_count * 10, 75].min
default['httpd']['performance']['thread_limit'] = 64
default['httpd']['performance']['threads_per_child'] = 25
default['httpd']['performance']['max_request_workers'] = [cpu_count * 15, 400].min
default['httpd']['performance']['server_limit'] =
  (node['httpd']['performance']['max_request_workers'] / node['httpd']['performance']['threads_per_child']).ceil

# Prefork MPM specific settings
default['httpd']['performance']['prefork']['start_servers'] = [cpu_count, 5].max
default['httpd']['performance']['prefork']['min_spare_servers'] = [cpu_count * 2, 5].max
default['httpd']['performance']['prefork']['max_spare_servers'] = [cpu_count * 4, 10].max
default['httpd']['performance']['prefork']['server_limit'] = 256
default['httpd']['performance']['prefork']['max_clients'] =
  [node['httpd']['performance']['prefork']['server_limit'], node['httpd']['performance']['max_clients']].min
default['httpd']['performance']['prefork']['max_requests_per_child'] = 4000

# Worker MPM specific settings
default['httpd']['performance']['worker']['start_servers'] = [cpu_count, 3].max
default['httpd']['performance']['worker']['min_spare_threads'] = [cpu_count * 5, 25].min
default['httpd']['performance']['worker']['max_spare_threads'] = [cpu_count * 10, 75].min
default['httpd']['performance']['worker']['thread_limit'] = 64
default['httpd']['performance']['worker']['threads_per_child'] = [cpu_count * 3, 25].min
default['httpd']['performance']['worker']['server_limit'] = 16

# Base configuration
default['httpd']['config']['timeout'] = 300
default['httpd']['config']['keep_alive'] = 'On'
default['httpd']['config']['keep_alive_timeout'] = 5
default['httpd']['config']['keep_alive_requests'] = 100
default['httpd']['config']['access_file_name'] = '.htaccess'
default['httpd']['config']['server_root'] = node['httpd']['root_dir']
default['httpd']['config']['user'] = node['httpd']['user']
default['httpd']['config']['group'] = node['httpd']['group']
default['httpd']['config']['server_admin'] = 'webmaster@localhost'
default['httpd']['config']['hostname_lookups'] = 'Off'
default['httpd']['config']['listen'] = ['*:80']
default['httpd']['config']['directory_index'] = 'index.html index.htm index.php'
default['httpd']['config']['file_etag'] = 'MTime Size'
default['httpd']['config']['max_request_line'] = 8190
default['httpd']['config']['enable_http2'] = true

# Log configuration
default['httpd']['config']['log_level'] = 'warn'
default['httpd']['config']['log_format'] = {
  'combined' => '%h %l %u %t \"%r\" %>s %b \"%<Referer>si\" \"%{User-Agent}i\"',
  'common' => '%h %l %u %t \"%r\" %>s %b',
  'json' => '{"time":"%t","remoteIP":"%a","host":"%V","request":"%U","query":"%q","method":"%m","status":"%>s","userAgent":"%{User-agent}i","referer":"%<Referer>si","requestTime":"%D"}',
}
default['httpd']['config']['enable_access_log'] = true
default['httpd']['config']['rotate_logs'] = true

# Security configuration
default['httpd']['security']['server_tokens'] = 'Prod'
default['httpd']['security']['server_signature'] = 'Off'
default['httpd']['security']['trace_enable'] = 'Off'
default['httpd']['security']['expose_php'] = 'Off'
default['httpd']['security']['cgi_fix_path_info'] = 'On'
default['httpd']['security']['disable_directory_listing'] = true
default['httpd']['security']['disable_server_info'] = true
default['httpd']['security']['disable_server_status'] = true
default['httpd']['security']['disable_cgi'] = false
default['httpd']['security']['secure_cookie'] = true
default['httpd']['security']['clickjacking_protection'] = true
default['httpd']['security']['xss_protection'] = true
default['httpd']['security']['mime_sniffing_protection'] = true
default['httpd']['security']['content_security_policy'] = "default-src 'self'; script-src 'self'"

# SSL/TLS Configuration
default['httpd']['ssl']['enabled'] = false
default['httpd']['ssl']['port'] = 443
default['httpd']['ssl']['use_strong_ciphers'] = true
default['httpd']['ssl']['protocol'] = %w(all -SSLv3 -TLSv1 -TLSv1.1)
default['httpd']['ssl']['cipher_suite'] =
  'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384'
default['httpd']['ssl']['honor_cipher_order'] = 'on'
default['httpd']['ssl']['session_tickets'] = 'off'
default['httpd']['ssl']['session_timeout'] = '300'
default['httpd']['ssl']['session_cache'] = 'shmcb:/var/cache/mod_ssl/ssl_scache(512000)'
default['httpd']['ssl']['certificate'] = nil
default['httpd']['ssl']['certificate_key'] = nil
default['httpd']['ssl']['certificate_chain'] = nil
default['httpd']['ssl']['hsts'] = true
default['httpd']['ssl']['hsts_max_age'] = 31_536_000
default['httpd']['ssl']['hsts_include_subdomains'] = true
default['httpd']['ssl']['hsts_preload'] = false
default['httpd']['ssl']['ocsp_stapling'] = true
default['httpd']['ssl']['auto_redirect_http'] = true

# Default modules to enable
default['httpd']['modules'] = %w(
  access_compat
  alias
  auth_basic
  authn_core
  authn_file
  authz_core
  authz_host
  authz_user
  autoindex
  deflate
  dir
  env
  expires
  filter
  headers
  mime
  negotiation
  reqtimeout
  rewrite
  setenvif
  socache_shmcb
  status
  ssl
)

# Default modules to disable
default['httpd']['disabled_modules'] = %w(
  cgi
)

# Extra modules to install
default['httpd']['extra_modules'] = %w()

# Default virtual hosts
default['httpd']['default_vhost'] = {
  'port' => 80,
  'document_root' => '/var/www/html',
  'server_name' => node['fqdn'] || 'localhost',
  'server_admin' => 'webmaster@localhost',
  'directory_options' => 'FollowSymLinks',
  'allow_override' => 'None',
  'directory_index' => 'index.html',
  'error_log' => 'logs/error_log',
  'custom_log' => 'logs/access_log combined',
  'enabled' => true,
}

# Define virtual hosts to create (empty by default)
default['httpd']['vhosts'] = {}

# Define default directories
default['httpd']['default_directories'] = [
  {
    'path' => '/var/www/html',
    'options' => 'Indexes FollowSymLinks',
    'allow_override' => 'None',
    'require' => 'all granted',
  },
]

# OS-specific tuning
case node['platform_family']
when 'rhel', 'fedora', 'amazon'
  # SELinux configurations
  default['httpd']['selinux']['enabled'] = true
  default['httpd']['selinux']['ports'] = [80, 443]
  default['httpd']['selinux']['docroot_context'] = 'httpd_sys_content_t'
  default['httpd']['selinux']['allow_http_connections'] = true
  default['httpd']['selinux']['allow_network_connect'] = false
when 'debian'
  # AppArmor configurations
  default['httpd']['apparmor']['enabled'] = true
  default['httpd']['apparmor']['profile'] = '/etc/apparmor.d/usr.sbin.apache2'
when 'freebsd'
  # FreeBSD rc.conf settings
  default['httpd']['rc_conf']['apache24_enable'] = 'YES'
when 'mac_os_x'
  # macOS uses Homebrew services
  default['httpd']['use_homebrew_service'] = true
end

# Firewall configuration
default['httpd']['firewall']['enabled'] = true
default['httpd']['firewall']['allow_ports'] = [80, 443]
default['httpd']['firewall']['source_addresses'] = %w(0.0.0.0/0 ::/0)

# Monitoring configuration
default['httpd']['monitoring']['enabled'] = true
default['httpd']['monitoring']['status_path'] = '/server-status'
default['httpd']['monitoring']['restricted_access'] = true
default['httpd']['monitoring']['allowed_ips'] = %w(127.0.0.1 ::1)

# Default sites data directory
default['httpd']['sites_dir'] = '/var/www'

# Logging
default['httpd']['logrotate']['enabled'] = true
default['httpd']['logrotate']['rotate'] = 52
default['httpd']['logrotate']['frequency'] = 'weekly'
default['httpd']['logrotate']['options'] = %w(missingok compress delaycompress notifempty create)
default['httpd']['logrotate']['postrotate'] = case node['platform_family']
                                              when 'rhel', 'fedora', 'amazon'
                                                '/bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true'
                                              when 'debian'
                                                '/bin/systemctl reload apache2.service > /dev/null 2>/dev/null || true'
                                              when 'freebsd'
                                                '/usr/sbin/service apache24 reload > /dev/null 2>/dev/null || true'
                                              when 'mac_os_x'
                                                nil # macOS uses newsyslog, not logrotate
                                              end

# Health check and monitoring
default['httpd']['health_check']['enabled'] = true
default['httpd']['health_check']['path'] = '/health-check'
default['httpd']['health_check']['content'] = 'OK'

# Telemetry configuration
default['httpd']['telemetry']['enabled'] = false
default['httpd']['telemetry']['prometheus']['enabled'] = true
default['httpd']['telemetry']['prometheus']['scrape_uri'] = '/server-status?auto'
default['httpd']['telemetry']['prometheus']['telemetry_path'] = '/metrics'
default['httpd']['telemetry']['prometheus']['metrics'] = %w(
  connections
  scoreboard
  cpu
  requests
  throughput
  response_time
  workers
)
default['httpd']['telemetry']['prometheus']['allow_ips'] = %w(127.0.0.1 ::1)
default['httpd']['telemetry']['grafana']['enabled'] = false
default['httpd']['telemetry']['grafana']['url'] = 'http://localhost:3000'
default['httpd']['telemetry']['grafana']['datasource'] = 'Prometheus'
default['httpd']['telemetry']['grafana']['api_key'] = nil

# -----------------------------------------------------------------------------
# Let's Encrypt / ACME Configuration
# -----------------------------------------------------------------------------

# Enable Let's Encrypt certificate automation
default['httpd']['letsencrypt']['enabled'] = false

# Email for certificate expiry notifications (required for production)
default['httpd']['letsencrypt']['email'] = nil

# Domains to request certificates for
# Example: ['example.com', 'www.example.com']
default['httpd']['letsencrypt']['domains'] = []

# ACME server (use staging for testing)
default['httpd']['letsencrypt']['server'] = 'https://acme-v02.api.letsencrypt.org/directory'
default['httpd']['letsencrypt']['staging_server'] = 'https://acme-staging-v02.api.letsencrypt.org/directory'

# Use staging server for testing
default['httpd']['letsencrypt']['staging'] = false

# Certbot package name by platform
default['httpd']['letsencrypt']['certbot_package'] = case node['platform_family']
                                                     when 'rhel', 'fedora', 'amazon'
                                                       'certbot'
                                                     when 'debian'
                                                       'certbot'
                                                     when 'freebsd'
                                                       'py39-certbot'
                                                     else
                                                       'certbot'
                                                     end

# Apache plugin package
default['httpd']['letsencrypt']['apache_plugin'] = case node['platform_family']
                                                   when 'rhel', 'fedora', 'amazon'
                                                     'python3-certbot-apache'
                                                   when 'debian'
                                                     'python3-certbot-apache'
                                                   when 'freebsd'
                                                     'py39-certbot-apache'
                                                   else
                                                     'python3-certbot-apache'
                                                   end

# Certificate directory
default['httpd']['letsencrypt']['cert_dir'] = '/etc/letsencrypt/live'

# Renewal configuration
default['httpd']['letsencrypt']['renewal']['enabled'] = true
default['httpd']['letsencrypt']['renewal']['schedule'] = '0 3 * * *' # 3 AM daily
default['httpd']['letsencrypt']['renewal']['pre_hook'] = nil
default['httpd']['letsencrypt']['renewal']['post_hook'] = nil
default['httpd']['letsencrypt']['renewal']['deploy_hook'] = nil

# Challenge type: 'http' or 'dns'
default['httpd']['letsencrypt']['challenge'] = 'http'

# Webroot path for HTTP challenge
default['httpd']['letsencrypt']['webroot'] = '/var/www/letsencrypt'

# RSA key size
default['httpd']['letsencrypt']['key_size'] = 4096

# Enable OCSP stapling for Let's Encrypt certs
default['httpd']['letsencrypt']['ocsp_stapling'] = true

# Agree to terms of service automatically
default['httpd']['letsencrypt']['agree_tos'] = true

# -----------------------------------------------------------------------------
# ModSecurity / WAF Configuration
# -----------------------------------------------------------------------------

# Enable ModSecurity
default['httpd']['modsecurity']['enabled'] = false

# ModSecurity mode: 'DetectionOnly' or 'On'
default['httpd']['modsecurity']['mode'] = 'DetectionOnly'

# Package names by platform
default['httpd']['modsecurity']['package'] = case node['platform_family']
                                             when 'rhel', 'fedora', 'amazon'
                                               'mod_security'
                                             when 'debian'
                                               'libapache2-mod-security2'
                                             when 'freebsd'
                                               'ap24-mod_security'
                                             else
                                               'libapache2-mod-security2'
                                             end

# OWASP Core Rule Set version
default['httpd']['modsecurity']['crs_version'] = '3.3.5'

# CRS download URL
default['httpd']['modsecurity']['crs_url'] = lazy do
  "https://github.com/coreruleset/coreruleset/archive/refs/tags/v#{node['httpd']['modsecurity']['crs_version']}.tar.gz"
end

# CRS installation directory
default['httpd']['modsecurity']['crs_dir'] = '/etc/modsecurity/crs'

# ModSecurity configuration directory
default['httpd']['modsecurity']['conf_dir'] = case node['platform_family']
                                              when 'rhel', 'fedora', 'amazon'
                                                '/etc/httpd/modsecurity.d'
                                              when 'debian'
                                                '/etc/modsecurity'
                                              when 'freebsd'
                                                '/usr/local/etc/modsecurity'
                                              else
                                                '/etc/modsecurity'
                                              end

# Audit log settings
default['httpd']['modsecurity']['audit_log']['enabled'] = true
default['httpd']['modsecurity']['audit_log']['type'] = 'Serial'
default['httpd']['modsecurity']['audit_log']['path'] = '/var/log/modsecurity/modsec_audit.log'
default['httpd']['modsecurity']['audit_log']['parts'] = 'ABIJDEFHZ'
default['httpd']['modsecurity']['audit_log']['relevant_only'] = false

# Request body settings
default['httpd']['modsecurity']['request_body']['enabled'] = true
default['httpd']['modsecurity']['request_body']['limit'] = 13_107_200
default['httpd']['modsecurity']['request_body']['no_files_limit'] = 131_072
default['httpd']['modsecurity']['request_body']['limit_action'] = 'Reject'

# Response body settings
default['httpd']['modsecurity']['response_body']['enabled'] = false
default['httpd']['modsecurity']['response_body']['limit'] = 1_048_576
default['httpd']['modsecurity']['response_body']['limit_action'] = 'ProcessPartial'
default['httpd']['modsecurity']['response_body']['mime_types'] = %w(
  text/plain
  text/html
  text/xml
  application/json
)

# Rule engine settings
default['httpd']['modsecurity']['paranoia_level'] = 1
default['httpd']['modsecurity']['anomaly_inbound_threshold'] = 5
default['httpd']['modsecurity']['anomaly_outbound_threshold'] = 4

# Exclusions for false positives
# Example: [{ 'id' => '920350', 'reason' => 'False positive for API' }]
default['httpd']['modsecurity']['rule_exclusions'] = []

# IP whitelist for bypassing WAF
default['httpd']['modsecurity']['ip_whitelist'] = []

# Custom rules
default['httpd']['modsecurity']['custom_rules'] = []

# Enable GeoIP blocking
default['httpd']['modsecurity']['geoip']['enabled'] = false
default['httpd']['modsecurity']['geoip']['database'] = '/usr/share/GeoIP/GeoLite2-Country.mmdb'
default['httpd']['modsecurity']['geoip']['blocked_countries'] = []

# Bot detection settings
default['httpd']['modsecurity']['bot_detection']['enabled'] = true
default['httpd']['modsecurity']['bot_detection']['block_bad_bots'] = true
default['httpd']['modsecurity']['bot_detection']['allow_good_bots'] = true
