# frozen_string_literal: true

#
# Cookbook:: httpd
# Recipe:: ssl
#
# Copyright:: 2024, Thomas Vincent
# License:: Apache-2.0
#
# This recipe configures SSL/TLS for Apache HTTP Server with support for
# Let's Encrypt certificates via certbot, or custom certificates.
#

# Determine platform-specific settings
case node['platform_family']
when 'debian'
  apache_service = 'apache2'
  ssl_conf_dir = '/etc/apache2/conf-available'
  ssl_enabled_dir = '/etc/apache2/conf-enabled'
  ssl_module_pkg = 'openssl'
  certbot_apache_pkg = 'python3-certbot-apache'
  enable_ssl_cmd = 'a2enmod ssl'
  enable_conf_cmd = 'a2enconf ssl-hardening'
when 'rhel', 'fedora', 'amazon'
  apache_service = 'httpd'
  ssl_conf_dir = '/etc/httpd/conf.d'
  ssl_enabled_dir = nil
  ssl_module_pkg = 'mod_ssl'
  certbot_apache_pkg = 'python3-certbot-apache'
  enable_ssl_cmd = nil
  enable_conf_cmd = nil
else
  apache_service = 'httpd'
  ssl_conf_dir = '/etc/httpd/conf.d'
  ssl_enabled_dir = nil
  ssl_module_pkg = 'mod_ssl'
  certbot_apache_pkg = 'certbot-apache'
  enable_ssl_cmd = nil
  enable_conf_cmd = nil
end

# Install SSL dependencies
package ssl_module_pkg do
  action :install
end

# Enable SSL module on Debian-based systems
execute 'a2enmod ssl' do
  command enable_ssl_cmd
  only_if { node['platform_family'] == 'debian' }
  not_if { ::File.exist?('/etc/apache2/mods-enabled/ssl.load') }
  notifies :restart, "service[#{apache_service}]", :delayed
end

# Create SSL configuration directory
directory '/etc/apache2/ssl' do
  owner 'root'
  group 'root'
  mode '0750'
  recursive true
  only_if { node['platform_family'] == 'debian' }
end

directory '/etc/httpd/ssl' do
  owner 'root'
  group 'root'
  mode '0750'
  recursive true
  only_if { node['platform_family'] != 'debian' }
end

# Create SSL hardening configuration with modern cipher suites
# Based on Mozilla SSL Configuration Generator (Modern profile)
template "#{ssl_conf_dir}/ssl-hardening.conf" do
  source 'ssl-hardening.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    ssl_protocols: node['httpd']['ssl']['protocols'] || 'TLSv1.2 TLSv1.3',
    ssl_ciphers: node['httpd']['ssl']['ciphers'] || 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384',
    ssl_honor_cipher_order: node['httpd']['ssl']['honor_cipher_order'] || 'off',
    ssl_session_timeout: node['httpd']['ssl']['session_timeout'] || '1d',
    ssl_session_cache: node['httpd']['ssl']['session_cache'] || 'shmcb:/var/run/apache2/ssl_scache(512000)',
    hsts_enabled: node['httpd']['ssl']['hsts']['enabled'] || true,
    hsts_max_age: node['httpd']['ssl']['hsts']['max_age'] || 63_072_000,
    ocsp_stapling: node['httpd']['ssl']['ocsp_stapling'] || true
  )
  notifies :restart, "service[#{apache_service}]", :delayed
end

# Enable SSL hardening configuration on Debian-based systems
execute 'a2enconf ssl-hardening' do
  command enable_conf_cmd
  only_if { node['platform_family'] == 'debian' }
  only_if { enable_conf_cmd }
  not_if { ::File.exist?('/etc/apache2/conf-enabled/ssl-hardening.conf') }
  notifies :restart, "service[#{apache_service}]", :delayed
end

# Let's Encrypt / Certbot integration
if node['httpd']['ssl']['letsencrypt']['enabled']
  # Install certbot packages
  package 'certbot' do
    action :install
  end

  package certbot_apache_pkg do
    action :install
  end

  # Obtain certificates for configured domains
  node['httpd']['ssl']['letsencrypt']['domains'].each do |domain|
    execute "certbot-#{domain}" do
      command lazy {
        cmd = [
          '/usr/bin/certbot', 'certonly',
          '--apache',
          '--non-interactive',
          '--agree-tos',
          '--email', node['httpd']['ssl']['letsencrypt']['contact'],
          '-d', domain
        ]
        cmd << '--staging' if node['httpd']['ssl']['letsencrypt']['staging']
        cmd.join(' ')
      }
      not_if { ::File.exist?("/etc/letsencrypt/live/#{domain}/fullchain.pem") }
      notifies :restart, "service[#{apache_service}]", :delayed
    end
  end

  # Configure automatic certificate renewal
  cron 'certbot-renewal' do
    command "/usr/bin/certbot renew --quiet --deploy-hook \"systemctl reload #{apache_service}\""
    hour '3'
    minute '30'
    user 'root'
    action :create
  end
end

# Ensure Apache service is defined for notifications
service apache_service do
  action :nothing
end
