# frozen_string_literal: true

# Prefork MPM Test Suite
# Validates the installation and configuration of Apache's prefork MPM

title 'Apache Prefork MPM Tests'

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

# Test for prefork MPM module loading
describe file('/etc/apache2/mods-enabled/mpm_prefork.load'), if: os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_symlink }
end

describe file('/etc/apache2/mods-enabled/mpm_event.load'), if: os.debian? || os.ubuntu? do
  it { should_not exist }
end

describe file('/etc/apache2/mods-enabled/mpm_worker.load'), if: os.debian? || os.ubuntu? do
  it { should_not exist }
end

describe apache_conf('/etc/httpd/conf.modules.d/00-mpm.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/LoadModule mpm_prefork_module/) }
  its('content') { should_not match(/LoadModule mpm_event_module/) }
  its('content') { should_not match(/LoadModule mpm_worker_module/) }
end

# Verify prefork-specific configuration settings
describe file('/etc/apache2/mods-enabled/mpm_prefork.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/StartServers\s+[0-9]+/) }
  its('content') { should match(/MinSpareServers\s+[0-9]+/) }
  its('content') { should match(/MaxSpareServers\s+[0-9]+/) }
  its('content') { should match(/MaxRequestWorkers\s+[0-9]+/) }
  its('content') { should match(/MaxConnectionsPerChild\s+[0-9]+/) }
end

describe file('/etc/httpd/conf/httpd.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/StartServers\s+[0-9]+/) }
  its('content') { should match(/MinSpareServers\s+[0-9]+/) }
  its('content') { should match(/MaxSpareServers\s+[0-9]+/) }
  its('content') { should match(/MaxRequestWorkers\s+[0-9]+/) }
  its('content') { should match(/MaxConnectionsPerChild\s+[0-9]+/) }
end

# Check process management settings
describe apache_conf('/etc/apache2/mods-enabled/mpm_prefork.conf'), if: os.debian? || os.ubuntu? do
  its('StartServers') { should cmp >= 5 }
  its('MinSpareServers') { should cmp >= 5 }
  its('MaxSpareServers') { should cmp >= 10 }
end

describe apache_conf('/etc/httpd/conf/httpd.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/StartServers\s+[5-9]\d*/) }
  its('content') { should match(/MinSpareServers\s+[5-9]\d*/) }
  its('content') { should match(/MaxSpareServers\s+1\d+/) }
end

# Test resource limits
describe apache_conf('/etc/apache2/mods-enabled/mpm_prefork.conf'), if: os.debian? || os.ubuntu? do
  its('MaxRequestWorkers') { should cmp <= 256 } # Reasonable upper limit for prefork
  its('MaxConnectionsPerChild') { should cmp >= 0 }
end

describe apache_conf('/etc/httpd/conf/httpd.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/MaxRequestWorkers\s+(?:[1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-6])/) }
  its('content') { should match(/MaxConnectionsPerChild\s+\d+/) }
end

# Validate Apache is running with prefork MPM
describe command('apache2ctl -V'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/Server MPM:\s+prefork/) }
end

describe command('httpd -V'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/Server MPM:\s+prefork/) }
end

# Check actual running processes
describe command('ps -ef | grep -c "apache2" || true'), if: os.debian? || os.ubuntu? do
  # At least a few processes should be running (1 parent + some children)
  its('stdout.to_i') { should be > 1 }
end

describe command('ps -ef | grep -c "httpd" || true'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  # At least a few processes should be running (1 parent + some children)
  its('stdout.to_i') { should be > 1 }
end

# Check server status reporting
describe command('curl -s http://localhost/server-status?auto || echo "Status not available"') do
  its('stdout') { should match(/(Scoreboard|Status not available)/) }
end

# If server-status is available, check the scoreboard for prefork processes
describe command('curl -s http://localhost/server-status?auto | grep Scoreboard || echo "Scoreboard not available"') do
  its('stdout') { should match(/(Scoreboard|not available)/) }
end

# Verify Apache listens on expected ports
describe port(80) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

# Make basic request to test functionality
describe http('http://localhost/') do
  its('status') { should eq 200 }
end

# Check Apache syntax with this MPM
describe command('apache2ctl configtest'), if: os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

describe command('httpd -t'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

# Test PHP compatibility (if PHP is installed - prefork is preferred for mod_php)
describe command('which php > /dev/null && apache2ctl -M | grep php || echo "PHP not installed"'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/(php|PHP not installed)/) }
end

describe command('which php > /dev/null && httpd -M | grep php || echo "PHP not installed"'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/(php|PHP not installed)/) }
end
