# frozen_string_literal: true

# Advanced Logging Test Suite
# Validates Apache's logging configuration, including JSON logging,
# rotation, custom formats, buffer settings, and log levels

title 'Advanced Logging Tests'

# Core Apache installation
describe service('apache2'), :if => os.debian? || os.ubuntu? do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('httpd'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# Log file existence and permissions
describe file('/var/log/apache2/error.log'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('owner') { should eq 'root' }
  its('group') { should eq 'adm' }
  its('mode') { should cmp '0640' }
end

describe file('/var/log/apache2/access.log'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('owner') { should eq 'root' }
  its('group') { should eq 'adm' }
  its('mode') { should cmp '0640' }
end

describe file('/var/log/httpd/error_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0600' }
end

describe file('/var/log/httpd/access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0600' }
end

# JSON logging configuration
describe file('/etc/apache2/conf-enabled/logging.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /LogFormat\s+{\s+"timestamp/i }
end

describe file('/etc/httpd/conf.d/logging.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match /LogFormat\s+{\s+"timestamp/i }
end

# Check for valid JSON in access log (assuming JSON logging is enabled)
describe file('/var/log/apache2/access.log'), :if => os.debian? || os.ubuntu? do
  its('content') { should match /^\{\s*"timestamp".*\}\s*$/ }
end

describe file('/var/log/httpd/access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /^\{\s*"timestamp".*\}\s*$/ }
end

# Log rotation configuration
describe file('/etc/logrotate.d/apache2'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /rotate\s+10/ }
  its('content') { should match /daily/ }
  its('content') { should match /compress/ }
  its('content') { should match /size\s+100M/ }
end

describe file('/etc/logrotate.d/httpd'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match /rotate\s+10/ }
  its('content') { should match /daily/ }
  its('content') { should match /compress/ }
  its('content') { should match /size\s+100M/ }
end

# Error log level configuration
describe apache_conf, :if => os.debian? || os.ubuntu? do
  its('LogLevel') { should eq 'warn' }
end

describe apache_conf, :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('LogLevel') { should eq 'warn' }
end

# Custom log format configuration
describe apache_conf('/etc/apache2/conf-enabled/logging.conf'), :if => os.debian? || os.ubuntu? do
  its('LogFormat') { should include '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"' }
end

describe apache_conf('/etc/httpd/conf.d/logging.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('LogFormat') { should include '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"' }
end

# Buffer settings
describe apache_conf('/etc/apache2/conf-enabled/logging.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match /BufferedLogs\s+On/ }
  its('content') { should match /CustomLog.*\s+8192/ }
end

describe apache_conf('/etc/httpd/conf.d/logging.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /BufferedLogs\s+On/ }
  its('content') { should match /CustomLog.*\s+8192/ }
end

# Make a request and check log for activity
describe command('curl -s -o /dev/null -w "%{http_code}" http://localhost/') do
  its('stdout') { should match /^(200|301|302|304|403|404)$/ }
end

# Log file should have recent entries
describe command('stat -c %Y /var/log/apache2/access.log'), :if => os.debian? || os.ubuntu? do
  its('stdout.to_i') { should be > Time.now.to_i - 300 }
end

describe command('stat -c %Y /var/log/httpd/access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout.to_i') { should be > Time.now.to_i - 300 }
end

# Additional fields in logs
describe file('/var/log/apache2/access.log'), :if => os.debian? || os.ubuntu? do
  its('content') { should match /(?:"response_time_ms"|"processing_time"|"responseTime")/ }
end

describe file('/var/log/httpd/access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /(?:"response_time_ms"|"processing_time"|"responseTime")/ }
end

# JSON log format validation
describe command('grep -E "^\\{.*\\}$" /var/log/apache2/access.log | head -1 | jq .'), :if => os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /"timestamp":/ }
  its('stdout') { should match /"remoteIp":/ }
  its('stdout') { should match /"status":/ }
  its('stdout') { should match /"request":/ }
end

describe command('grep -E "^\\{.*\\}$" /var/log/httpd/access_log | head -1 | jq .'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /"timestamp":/ }
  its('stdout') { should match /"remoteIp":/ }
  its('stdout') { should match /"status":/ }
  its('stdout') { should match /"request":/ }
end

# Check log rotation configuration
describe file('/etc/logrotate.d/apache2'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /rotate\s+#{node['httpd']['logging']['rotation']['keep'] || 10}/ }
  its('content') { should match /#{node['httpd']['logging']['rotation']['interval'] || 'daily'}/ }
  its('content') { should match /#{node['httpd']['logging']['rotation']['compress'] ? 'compress' : 'nocompress'}/ }
  its('content') { should match /size\s+#{node['httpd']['logging']['rotation']['max_size'] || '100M'}/ }
end

describe file('/etc/logrotate.d/httpd'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match /rotate\s+#{node['httpd']['logging']['rotation']['keep'] || 10}/ }
  its('content') { should match /#{node['httpd']['logging']['rotation']['interval'] || 'daily'}/ }
  its('content') { should match /#{node['httpd']['logging']['rotation']['compress'] ? 'compress' : 'nocompress'}/ }
  its('content') { should match /size\s+#{node['httpd']['logging']['rotation']['max_size'] || '100M'}/ }
end

# Check for buffer configuration
describe apache_conf('/etc/apache2/conf-enabled/logging.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match /BufferedLogs\s+On/ }
  its('content') { should match /CustomLog.*\s+#{node['httpd']['logging']['buffer_size']}/ }
end

describe apache_conf('/etc/httpd/conf.d/logging.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /BufferedLogs\s+On/ }
  its('content') { should match /CustomLog.*\s+#{node['httpd']['logging']['buffer_size']}/ }
end

# Check Apache error handling for log-related issues
describe command('apache2ctl -t'), :if => os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

describe command('httpd -t'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

# Test log file permissions
describe file('/var/log/apache2/access.log'), :if => os.debian? || os.ubuntu? do
  its('owner') { should eq 'www-data' }
  its('group') { should eq 'adm' }
  its('mode') { should cmp '0640' }
end

describe file('/var/log/httpd/access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('owner') { should eq 'apache' }
  its('group') { should eq 'apache' }
  its('mode') { should cmp '0640' }
end

# Test log directory permissions
describe file('/var/log/apache2'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_directory }
  its('owner') { should eq 'root' }
  its('group') { should eq 'adm' }
  its('mode') { should cmp '0750' }
end

describe file('/var/log/httpd'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  it { should be_directory }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0755' }
end

