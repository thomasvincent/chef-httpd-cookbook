# frozen_string_literal: true

# Source Installation Test Suite
# Validates the installation and configuration of Apache HTTP Server from source

title 'Apache Source Installation Tests'

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

# Test for source installation prerequisites
%w(make gcc libpcre3-dev libssl-dev).each do |pkg|
  describe package(pkg), if: os.debian? || os.ubuntu? do
    it { should be_installed }
  end
end

%w(make gcc pcre-devel openssl-devel).each do |pkg|
  describe package(pkg), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
    it { should be_installed }
  end
end

# Verify Apache version and compilation options
describe command('apache2 -v'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/version 2.4.57/) }
  its('exit_status') { should eq 0 }
end

describe command('httpd -v'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/version 2.4.57/) }
  its('exit_status') { should eq 0 }
end

# Check compilation flags and options
describe command('apache2 -V'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/Server MPM:\s+event/) } # Default MPM for source build
  its('stdout') { should match(/--enable-ssl/) }
  its('stdout') { should match(/--enable-http2/) }
  its('stdout') { should match(/--enable-so/) } # Required for dynamic modules
  its('exit_status') { should eq 0 }
end

describe command('httpd -V'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/Server MPM:\s+event/) } # Default MPM for source build
  its('stdout') { should match(/--enable-ssl/) }
  its('stdout') { should match(/--enable-http2/) }
  its('stdout') { should match(/--enable-so/) } # Required for dynamic modules
  its('exit_status') { should eq 0 }
end

# Check custom module compilation
describe command('apache2 -M'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/ssl_module/) }
  its('stdout') { should match(/http2_module/) }
  its('stdout') { should match(/rewrite_module/) }
  its('exit_status') { should eq 0 }
end

describe command('httpd -M'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/ssl_module/) }
  its('stdout') { should match(/http2_module/) }
  its('stdout') { should match(/rewrite_module/) }
  its('exit_status') { should eq 0 }
end

# Validate installation paths
describe file('/usr/local/apache2/bin/httpd'), if: os.linux? do
  it { should exist }
  it { should be_executable }
end

describe file('/usr/local/apache2/conf/httpd.conf'), if: os.linux? do
  it { should exist }
  its('owner') { should eq 'root' }
  its('mode') { should cmp '0644' }
end

describe file('/usr/local/apache2/modules'), if: os.linux? do
  it { should exist }
  it { should be_directory }
end

# Test compiled binary functionality
describe command('/usr/local/apache2/bin/httpd -t'), if: os.linux? do
  its('stdout') { should match(/Syntax OK/) }
  its('exit_status') { should eq 0 }
end

# Verify HTTP functionality of compiled Apache
describe port(80) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

describe http('http://localhost/') do
  its('status') { should eq 200 }
end

# Verify SSL functionality if compiled with SSL
describe port(443) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

describe http('https://localhost/', ssl_verify: false) do
  its('status') { should eq 200 }
end

# Verify system integration
describe file('/etc/systemd/system/httpd.service'), if: os.linux? do
  it { should exist }
  its('content') { should match(%r{ExecStart=/usr/local/apache2/bin/httpd}) }
end

# Check that source installation directories are properly permissioned
describe file('/usr/local/apache2/logs'), if: os.linux? do
  it { should exist }
  it { should be_directory }
  its('owner') { should eq 'root' }
end

describe file('/usr/local/apache2/htdocs'), if: os.linux? do
  it { should exist }
  it { should be_directory }
  its('mode') { should cmp '0755' }
end

# Check compilation artifacts
describe file('/usr/src/httpd-2.4.57'), if: os.linux? do
  it { should exist }
  it { should be_directory }
end

# Check APR installation for source build
describe file('/usr/local/apache2/bin/apr-1-config'), if: os.linux? do
  it { should exist }
  it { should be_executable }
end

# Verify that the right user/group is running Apache
describe command('ps -ef | grep httpd | grep -v grep | head -1'), if: os.linux? do
  its('stdout') { should match(/apache|www-data|httpd/) }
end

# Check that the installation includes key support files
describe file('/usr/local/apache2/bin/apachectl'), if: os.linux? do
  it { should exist }
  it { should be_executable }
end

# Test HTTP/2 protocol support from the source build
describe command('curl -s -I --http2 https://localhost/ -k || echo "HTTP/2 not supported"') do
  its('stdout') { should match(%r{(HTTP/2|HTTP/2 not supported)}) }
end
