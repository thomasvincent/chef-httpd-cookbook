# frozen_string_literal: true

#
# Cookbook:: httpd
# Recipe:: modsecurity
#
# Copyright:: 2025-2026, Thomas Vincent
# License:: Apache-2.0
#

# Configure ModSecurity WAF for Apache

return unless node['httpd']['modsecurity']['enabled']

# Install ModSecurity package
package 'modsecurity' do
  package_name node['httpd']['modsecurity']['package']
  action :install
end

# Install GeoIP database if enabled
if node['httpd']['modsecurity']['geoip']['enabled']
  package 'geoip-database' do
    package_name case node['platform_family']
                 when 'rhel', 'fedora', 'amazon'
                   'GeoIP-GeoLite-data'
                 when 'debian'
                   'geoip-database'
                 else
                   'geoip-database'
                 end
    action :install
  end
end

# Create ModSecurity directories
[
  node['httpd']['modsecurity']['conf_dir'],
  "#{node['httpd']['modsecurity']['conf_dir']}/rules",
  node['httpd']['modsecurity']['crs_dir'],
  ::File.dirname(node['httpd']['modsecurity']['audit_log']['path']),
].each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
    action :create
  end
end

# Download and extract OWASP Core Rule Set
ark 'coreruleset' do
  url node['httpd']['modsecurity']['crs_url']
  path node['httpd']['modsecurity']['crs_dir']
  strip_components 1
  action :put
  notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
end

# Create CRS setup configuration
template "#{node['httpd']['modsecurity']['crs_dir']}/crs-setup.conf" do
  source 'crs-setup.conf.erb'
  cookbook 'httpd'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    paranoia_level: node['httpd']['modsecurity']['paranoia_level'],
    anomaly_inbound_threshold: node['httpd']['modsecurity']['anomaly_inbound_threshold'],
    anomaly_outbound_threshold: node['httpd']['modsecurity']['anomaly_outbound_threshold'],
    geoip_enabled: node['httpd']['modsecurity']['geoip']['enabled'],
    geoip_database: node['httpd']['modsecurity']['geoip']['database'],
    blocked_countries: node['httpd']['modsecurity']['geoip']['blocked_countries']
  )
  notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  action :create
end

# Create main ModSecurity configuration
template "#{node['httpd']['modsecurity']['conf_dir']}/modsecurity.conf" do
  source 'modsecurity.conf.erb'
  cookbook 'httpd'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    mode: node['httpd']['modsecurity']['mode'],
    audit_log_enabled: node['httpd']['modsecurity']['audit_log']['enabled'],
    audit_log_type: node['httpd']['modsecurity']['audit_log']['type'],
    audit_log_path: node['httpd']['modsecurity']['audit_log']['path'],
    audit_log_parts: node['httpd']['modsecurity']['audit_log']['parts'],
    audit_log_relevant_only: node['httpd']['modsecurity']['audit_log']['relevant_only'],
    request_body_enabled: node['httpd']['modsecurity']['request_body']['enabled'],
    request_body_limit: node['httpd']['modsecurity']['request_body']['limit'],
    request_body_no_files_limit: node['httpd']['modsecurity']['request_body']['no_files_limit'],
    request_body_limit_action: node['httpd']['modsecurity']['request_body']['limit_action'],
    response_body_enabled: node['httpd']['modsecurity']['response_body']['enabled'],
    response_body_limit: node['httpd']['modsecurity']['response_body']['limit'],
    response_body_limit_action: node['httpd']['modsecurity']['response_body']['limit_action'],
    response_body_mime_types: node['httpd']['modsecurity']['response_body']['mime_types']
  )
  notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  action :create
end

# Create IP whitelist configuration if any IPs are whitelisted
if node['httpd']['modsecurity']['ip_whitelist'].any?
  template "#{node['httpd']['modsecurity']['conf_dir']}/rules/ip-whitelist.conf" do
    source 'waf-ip-whitelist.conf.erb'
    cookbook 'httpd'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      ip_whitelist: node['httpd']['modsecurity']['ip_whitelist']
    )
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
    action :create
  end
end

# Create rule exclusions for false positives
node['httpd']['modsecurity']['rule_exclusions'].each do |exclusion|
  httpd_waf_rule "exclusion_#{exclusion['id']}" do
    rule_id "900#{exclusion['id']}"
    exclusion true
    exclusion_target exclusion['id']
    exclusion_condition exclusion['condition'] if exclusion['condition']
    action :create
  end
end

# Create custom rules
node['httpd']['modsecurity']['custom_rules'].each_with_index do |rule, index|
  httpd_waf_rule rule['name'] || "custom_rule_#{index}" do
    rule_id rule['id'] || (990_000 + index)
    rule['action'] || 'block'
    phase rule['phase'] || 2
    operator rule['operator']
    target rule['target']
    pattern rule['pattern']
    message rule['message']
    severity rule['severity'] || 'WARNING'
    raw_rule rule['raw'] if rule['raw']
    action :create
  end
end

# Create Apache configuration to load ModSecurity
template "#{node['httpd']['conf_dir']}/modsecurity.load.conf" do
  source 'modsecurity.load.conf.erb'
  cookbook 'httpd'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    modsecurity_conf_dir: node['httpd']['modsecurity']['conf_dir'],
    crs_dir: node['httpd']['modsecurity']['crs_dir']
  )
  notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  action :create
end

# Enable ModSecurity module on Debian-based systems
if platform_family?('debian')
  execute 'enable_modsecurity' do
    command '/usr/sbin/a2enmod security2'
    not_if { ::File.exist?("#{node['httpd']['mod_enabled_dir']}/security2.load") }
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
    action :run
  end

  # Enable configuration
  link "#{node['httpd']['conf_enabled_dir'].sub('sites', 'conf')}/modsecurity.load.conf" do
    to "#{node['httpd']['conf_dir']}/modsecurity.load.conf"
    notifies :reload, "service[#{node['httpd']['service_name']}]", :delayed
  end
end

# Log information about ModSecurity configuration
log 'modsecurity_info' do
  message <<~MSG
    ModSecurity WAF has been configured for Apache.

    Mode: #{node['httpd']['modsecurity']['mode']}
    Paranoia Level: #{node['httpd']['modsecurity']['paranoia_level']}
    CRS Version: #{node['httpd']['modsecurity']['crs_version']}

    Audit Log: #{node['httpd']['modsecurity']['audit_log']['path']}

    Custom rules directory: #{node['httpd']['modsecurity']['conf_dir']}/rules

    To test ModSecurity:
      curl -I "http://localhost/?param=<script>alert(1)</script>"

    Note: DetectionOnly mode will log but not block attacks.
    Set mode to 'On' for active blocking.
  MSG
  level :info
end
