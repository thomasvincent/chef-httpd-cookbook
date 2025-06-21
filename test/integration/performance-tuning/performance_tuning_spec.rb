# frozen_string_literal: true

# Performance Tuning Test Suite
# Validates Apache's performance optimizations, including MPM configuration,
# thread and process limits, connection settings, and resource utilization

title 'Performance Tuning Tests'

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

# MPM Module Configuration (event MPM)
describe apache_conf('/etc/apache2/mods-enabled/mpm_event.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /StartServers\s+[0-9]+/ }
  its('content') { should match /MinSpareThreads\s+[0-9]+/ }
  its('content') { should match /MaxSpareThreads\s+[0-9]+/ }
  its('content') { should match /ThreadLimit\s+64/ }
  its('content') { should match /ThreadsPerChild\s+25/ }
  its('content') { should match /MaxRequestWorkers\s+400/ }
  its('content') { should match /MaxConnectionsPerChild\s+10000/ }
  its('content') { should match /ServerLimit\s+16/ }
end

describe apache_conf('/etc/httpd/conf.modules.d/00-mpm.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /LoadModule mpm_event_module/ }
end

describe apache_conf('/etc/httpd/conf/httpd.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /StartServers\s+[0-9]+/ }
  its('content') { should match /MinSpareThreads\s+[0-9]+/ }
  its('content') { should match /MaxSpareThreads\s+[0-9]+/ }
  its('content') { should match /ThreadLimit\s+64/ }
  its('content') { should match /ThreadsPerChild\s+25/ }
  its('content') { should match /MaxRequestWorkers\s+400/ }
  its('content') { should match /MaxConnectionsPerChild\s+10000/ }
  its('content') { should match /ServerLimit\s+16/ }
end

# Check that event MPM is enabled, not prefork or worker
describe file('/etc/apache2/mods-enabled/mpm_event.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_symlink }
end

describe file('/etc/apache2/mods-enabled/mpm_prefork.load'), :if => os.debian? || os.ubuntu? do
  it { should_not exist }
end

describe file('/etc/apache2/mods-enabled/mpm_worker.load'), :if => os.debian? || os.ubuntu? do
  it { should_not exist }
end

# Performance optimizations
describe apache_conf('/etc/apache2/apache2.conf'), :if => os.debian? || os.ubuntu? do
  its('Timeout') { should cmp <= 60 }
  its('KeepAlive') { should eq 'On' }
  its('MaxKeepAliveRequests') { should cmp >= 100 }
  its('KeepAliveTimeout') { should cmp <= 5 }
end

describe apache_conf('/etc/httpd/conf/httpd.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('Timeout') { should cmp <= 60 }
  its('KeepAlive') { should eq 'On' }
  its('MaxKeepAliveRequests') { should cmp >= 100 }
  its('KeepAliveTimeout') { should cmp <= 5 }
end

# Check running Apache processes
describe command('ps -ef | grep apache2 | grep -v grep | wc -l'), :if => os.debian? || os.ubuntu? do
  its('stdout.to_i') { should be >= 3 }  # At least a few Apache processes should be running
end

describe command('ps -ef | grep httpd | grep -v grep | wc -l'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout.to_i') { should be >= 3 }  # At least a few Apache processes should be running
end

# Check memory utilization of Apache processes
describe command('ps -o rss= -C apache2 | awk \'{sum+=$1} END {print sum/1024 " MB"}\''), :if => os.debian? || os.ubuntu? do
  its('stdout') { should_not be_empty }
  # We can't make specific assertions about memory usage as it depends on the system
end

describe command('ps -o rss= -C httpd | awk \'{sum+=$1} END {print sum/1024 " MB"}\''), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should_not be_empty }
  # We can't make specific assertions about memory usage as it depends on the system
end

# Check Apache status
describe command('curl -s http://localhost/server-status?auto') do
  its('exit_status') { should eq 0 }
end

# Performance-related modules
describe apache_conf('/etc/apache2/mods-enabled/expires.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe apache_conf('/etc/apache2/mods-enabled/deflate.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/etc/httpd/conf.modules.d/00-optional.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /LoadModule expires_module/ }
  its('content') { should match /LoadModule deflate_module/ }
end

# Cache settings (if enabled)
describe apache_conf('/etc/apache2/mods-enabled/cache.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe apache_conf('/etc/apache2/mods-enabled/cache_disk.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

# TCP settings
describe kernel_parameter('net.ipv4.tcp_fin_timeout') do
  its('value') { should cmp <= 30 }
end

describe kernel_parameter('net.core.somaxconn') do
  its('value') { should cmp >= 1024 }
end

# Additional performance checks from test file

# Check Apache config for performance settings
describe command(os.redhat? || os.name == 'amazon' || os.name == 'fedora' ? 'apachectl -t -D DUMP_RUN_CFG' : 'apache2ctl -t -D DUMP_RUN_CFG') do
  its('stdout') { should match(/ServerLimit\s+16/) }
  its('stdout') { should match(/MaxRequestWorkers\s+400/) }
  its('stdout') { should match(/ThreadsPerChild\s+25/) }
  its('stdout') { should match(/ThreadLimit\s+64/) }
end

# Check for the HTTP/2 module if enabled
describe command(os.redhat? || os.name == 'amazon' || os.name == 'fedora' ? 'apachectl -M' : 'apache2ctl -M') do
  its('stdout') { should match(/http2_module/) }
end

# Check if the socket buffer sizes are properly configured
describe kernel_parameter('net.core.rmem_max') do
  its('value') { should be >= 16_777_216 }
end

describe kernel_parameter('net.core.wmem_max') do
  its('value') { should be >= 16_777_216 }
end

# Verify system is configured for high concurrency
describe file('/proc/sys/fs/file-max') do
  its('content') { should match(/[0-9]{6,}/) } # Should be at least 6 digits (100000+)
end

# Check systemd overrides for Apache
if os.linux? && os.release.to_f >= 7
  systemd_service_name = os.redhat? || os.name == 'amazon' || os.name == 'fedora' ? 'httpd.service' : 'apache2.service'
  describe file("/etc/systemd/system/#{systemd_service_name}.d/override.conf") do
    it { should exist }
    its('content') { should match(/LimitNOFILE=65536/) }
  end
end

# Check for HTTP/2 protocol support in SSL configuration
describe apache_conf('/etc/apache2/mods-enabled/ssl.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match(/Protocols h2 http\/1.1/) }
end

describe apache_conf('/etc/httpd/conf.d/ssl.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/Protocols h2 http\/1.1/) }
end

# Check TCP settings for high-performance workloads
describe kernel_parameter('net.ipv4.tcp_slow_start_after_idle') do
  its('value') { should eq 0 }
end

describe kernel_parameter('net.ipv4.tcp_tw_reuse') do
  its('value') { should eq 1 }
end

# Check file descriptor limits for Apache user
describe command('ulimit -n') do
  its('stdout.to_i') { should be >= 65536 }
end

# Check for server status module for monitoring
describe apache_conf('/etc/apache2/mods-enabled/status.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/etc/httpd/conf.modules.d/00-base.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/LoadModule status_module/) }
end

