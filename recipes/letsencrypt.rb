# frozen_string_literal: true

#
# Cookbook:: httpd
# Recipe:: letsencrypt
#
# Copyright:: 2025-2026, Thomas Vincent
# License:: Apache-2.0
#

# Configure Let's Encrypt certificate automation for Apache

return unless node['httpd']['letsencrypt']['enabled']

# Validate email is provided
unless node['httpd']['letsencrypt']['email']
  Chef::Log.fatal('Let\'s Encrypt requires an email address. Set node[\'httpd\'][\'letsencrypt\'][\'email\']')
  raise 'Let\'s Encrypt email not configured'
end

# Install certbot and Apache plugin
package 'certbot' do
  package_name node['httpd']['letsencrypt']['certbot_package']
  action :install
end

package 'certbot-apache-plugin' do
  package_name node['httpd']['letsencrypt']['apache_plugin']
  action :install
end

# Create webroot directory for HTTP challenge
directory node['httpd']['letsencrypt']['webroot'] do
  owner node['httpd']['user']
  group node['httpd']['group']
  mode '0755'
  recursive true
  action :create
end

# Create .well-known/acme-challenge directory
directory "#{node['httpd']['letsencrypt']['webroot']}/.well-known/acme-challenge" do
  owner node['httpd']['user']
  group node['httpd']['group']
  mode '0755'
  recursive true
  action :create
end

# Create Apache alias configuration for ACME challenge
template "#{node['httpd']['conf_dir']}/letsencrypt-acme.conf" do
  source 'letsencrypt-acme.conf.erb'
  cookbook 'httpd'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    webroot: node['httpd']['letsencrypt']['webroot']
  )
  notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  action :create
end

# Enable on Debian-based systems
if platform_family?('debian')
  link "#{node['httpd']['conf_enabled_dir'].sub('sites', 'conf')}/letsencrypt-acme.conf" do
    to "#{node['httpd']['conf_dir']}/letsencrypt-acme.conf"
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  end
end

# Request certificates for each configured domain
node['httpd']['letsencrypt']['domains'].each do |domain_config|
  domain = domain_config.is_a?(Hash) ? domain_config['domain'] : domain_config
  alt_names = domain_config.is_a?(Hash) ? (domain_config['alt_names'] || []) : []

  httpd_certificate domain do
    email node['httpd']['letsencrypt']['email']
    alt_names alt_names
    provider 'letsencrypt'
    staging node['httpd']['letsencrypt']['staging']
    challenge node['httpd']['letsencrypt']['challenge']
    webroot node['httpd']['letsencrypt']['webroot']
    key_size node['httpd']['letsencrypt']['key_size']
    ocsp_stapling node['httpd']['letsencrypt']['ocsp_stapling']
    auto_renew node['httpd']['letsencrypt']['renewal']['enabled']
    pre_hook node['httpd']['letsencrypt']['renewal']['pre_hook']
    post_hook node['httpd']['letsencrypt']['renewal']['post_hook']
    deploy_hook node['httpd']['letsencrypt']['renewal']['deploy_hook']
    agree_tos node['httpd']['letsencrypt']['agree_tos']
    action :create
  end
end

# Configure automatic renewal via systemd timer or cron
if node['httpd']['letsencrypt']['renewal']['enabled']
  if systemd?
    # Create systemd timer for renewal
    systemd_unit 'certbot-renewal.timer' do
      content <<~UNIT
        [Unit]
        Description=Certbot renewal timer

        [Timer]
        OnCalendar=*-*-* 03:00:00
        RandomizedDelaySec=3600
        Persistent=true

        [Install]
        WantedBy=timers.target
      UNIT
      action [:create, :enable]
    end

    systemd_unit 'certbot-renewal.service' do
      content <<~UNIT
        [Unit]
        Description=Certbot renewal service
        After=network-online.target

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/certbot renew --quiet --deploy-hook "systemctl reload #{node['httpd']['service_name']}"
        PrivateTmp=true
      UNIT
      action :create
    end
  else
    # Create cron job for renewal
    cron 'certbot_renewal' do
      minute '0'
      hour '3'
      command "/usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload #{node['httpd']['service_name']}'"
      user 'root'
      action :create
    end
  end
end

# Configure OCSP stapling globally if enabled
if node['httpd']['letsencrypt']['ocsp_stapling']
  template "#{node['httpd']['conf_dir']}/ssl-ocsp-stapling.conf" do
    source 'ssl-ocsp-stapling.conf.erb'
    cookbook 'httpd'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      cache_path: case node['platform_family']
                  when 'rhel', 'fedora', 'amazon'
                    '/var/cache/httpd/ssl_stapling'
                  when 'debian'
                    '/var/cache/apache2/ssl_stapling'
                  else
                    '/var/cache/httpd/ssl_stapling'
                  end
    )
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
    action :create
  end

  # Enable on Debian-based systems
  if platform_family?('debian')
    link "#{node['httpd']['conf_enabled_dir'].sub('sites', 'conf')}/ssl-ocsp-stapling.conf" do
      to "#{node['httpd']['conf_dir']}/ssl-ocsp-stapling.conf"
      notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
    end
  end
end

# Log helpful information
log 'letsencrypt_info' do
  message <<~MSG
    Let's Encrypt has been configured for Apache.

    Domains configured: #{node['httpd']['letsencrypt']['domains'].join(', ')}
    Certificate directory: #{node['httpd']['letsencrypt']['cert_dir']}
    Automatic renewal: #{node['httpd']['letsencrypt']['renewal']['enabled'] ? 'Enabled' : 'Disabled'}

    To manually renew certificates:
      certbot renew

    To view certificate status:
      certbot certificates
  MSG
  level :info
end
