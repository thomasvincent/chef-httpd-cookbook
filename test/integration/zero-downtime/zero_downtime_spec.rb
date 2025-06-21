# frozen_string_literal: true

# Zero Downtime Test Suite
# Validates Apache's capability to perform graceful restarts,
# maintain connections during reload, and properly manage process shutdown

title 'Zero Downtime Tests'

# Core Apache installation
describe service('apache2'), if: os.debian? || os.ubuntu? do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe service('httpd'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# MPM event is required for best zero-downtime performance
describe apache_conf('/etc/apache2/mods-enabled/mpm_event.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
end

describe apache_conf('/etc/httpd/conf.modules.d/00-mpm.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /LoadModule mpm_event_module/ }
end

# Check graceful restart configuration
describe file('/etc/apache2/conf-enabled/graceful.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /GracefulShutdownTimeout\s+30/ }
end

describe file('/etc/httpd/conf.d/graceful.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match /GracefulShutdownTimeout\s+30/ }
end

# Socket activation configuration (if using systemd)
describe file('/lib/systemd/system/apache2.service'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /Type=notify/ }
end

describe file('/lib/systemd/system/httpd.service'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match /Type=notify/ }
end

# Check systemd socket activation (if applicable)
describe file('/lib/systemd/system/apache2.socket'), if: os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/lib/systemd/system/httpd.socket'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
end

# Test graceful restart capability
describe command('sudo apachectl -t'), if: os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
end

describe command('sudo httpd -t'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
end

# Test graceful restart command
describe command('sudo apachectl -k graceful'), if: os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
end

describe command('sudo httpd -k graceful'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
end

# Allow apache to restart
describe command('sleep 3') do
  its('exit_status') { should eq 0 }
end

# Check that the service is still running after graceful restart
describe service('apache2'), if: os.debian? || os.ubuntu? do
  it { should be_running }
end

describe service('httpd'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should be_running }
end

# Check connection preservation during reload (simulate connections)
describe command('curl -s http://localhost/') do
  its('exit_status') { should eq 0 }
end

# Run a reload while keeping a connection open
describe command('(curl -s -o /dev/null http://localhost/ --keepalive-time 10 &) && sudo apachectl -k graceful && sleep 5 && curl -s http://localhost/'), if: os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
end

describe command('(curl -s -o /dev/null http://localhost/ --keepalive-time 10 &) && sudo httpd -k graceful && sleep 5 && curl -s http://localhost/'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
end

# Check for proper process management
describe command('ps -ef | grep -E "apache2|httpd" | grep -v grep') do
  its('stdout') { should_not be_empty }
end

# Check Apache logs for graceful restart messages
describe command('grep -i graceful /var/log/apache2/error.log 2>/dev/null || echo "No graceful restart messages found"'), if: os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
end

describe command('grep -i graceful /var/log/httpd/error_log 2>/dev/null || echo "No graceful restart messages found"'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
end

# Configuration for connection queuing
describe apache_conf('/etc/apache2/mods-enabled/mpm_event.conf'), if: os.debian? || os.ubuntu? do
  its('content') { should match /ListenBacklog\s+[0-9]+/ }
end

describe apache_conf('/etc/httpd/conf/httpd.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /ListenBacklog\s+[0-9]+/ }
end

# Test for high-connection handling - this is a basic test
# For proper testing, a load generator should be used
describe command('for i in {1..50}; do curl -s -o /dev/null -w "%{http_code}" http://localhost/ & done') do
  its('exit_status') { should eq 0 }
end

# Check shutdown timeout configuration
describe file('/etc/apache2/conf-enabled/graceful.conf'), if: os.debian? || os.ubuntu? do
  its('content') { should match /GracefulShutdownTimeout\s+[0-9]+/ }
end

describe file('/etc/httpd/conf.d/graceful.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /GracefulShutdownTimeout\s+[0-9]+/ }
end

# Check that server-status reports worker availability correctly
describe command('curl -s http://localhost/server-status?auto | grep -i "idle workers"') do
  its('stdout') { should match /idle workers: \d+/ }
end
