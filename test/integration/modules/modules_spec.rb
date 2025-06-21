# frozen_string_literal: true

# Apache Modules Test Suite
# Validates the installation, configuration, and functionality of Apache modules

title 'Apache Modules Tests'

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

# Check required modules are installed and loaded
%w(proxy proxy_http rewrite).each do |mod|
  describe apache_conf("/etc/apache2/mods-enabled/#{mod}.load"), if: os.debian? || os.ubuntu? do
    it { should exist }
    it { should be_symlink }
  end
end

# For RHEL-based platforms, check modules in the Apache configuration
describe file('/etc/httpd/conf.modules.d/00-proxy.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/LoadModule proxy_module/) }
  its('content') { should match(/LoadModule proxy_http_module/) }
end

describe file('/etc/httpd/conf.modules.d/00-base.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/LoadModule rewrite_module/) }
end

# Check extra modules
%w(proxy_balancer lbmethod_byrequests).each do |mod|
  describe apache_conf("/etc/apache2/mods-enabled/#{mod}.load"), if: os.debian? || os.ubuntu? do
    it { should exist }
  end
end

describe file('/etc/httpd/conf.modules.d/00-proxy.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/LoadModule proxy_balancer_module/) }
  its('content') { should match(/LoadModule lbmethod_byrequests_module/) }
end

# Check for module configurations
describe file('/etc/apache2/mods-enabled/proxy.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/ProxyRequests Off/) }
end

describe file('/etc/httpd/conf.d/proxy.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/ProxyRequests Off/) }
end

# Test module functionality - Proxy module
describe command('curl -s -o /dev/null -w "%{http_code}" http://localhost/server-status') do
  its('stdout') { should match /(200|403)/ } # Either accessible or properly secured
end

# Verify that the rewrite module is working by checking if RewriteEngine is enabled
describe apache_conf('/etc/apache2/sites-enabled/000-default.conf'), if: os.debian? || os.ubuntu? do
  its('content') { should match(/RewriteEngine On/) }
end

describe apache_conf('/etc/httpd/conf.d/welcome.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/RewriteEngine On/) }
end

# Check for module dependencies
describe file('/etc/apache2/mods-enabled/proxy_http.load'), if: os.debian? || os.ubuntu? do
  its('content') { should match(/LoadModule proxy_module/) }
end

describe file('/etc/apache2/mods-enabled/proxy_balancer.load'), if: os.debian? || os.ubuntu? do
  its('content') { should match(/LoadModule proxy_module/) }
  its('content') { should match(/LoadModule slotmem_shm_module/) }
end

# Check loaded modules with Apache tools
describe command('apache2ctl -M'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/proxy_module/) }
  its('stdout') { should match(/proxy_http_module/) }
  its('stdout') { should match(/rewrite_module/) }
  its('stdout') { should match(/proxy_balancer_module/) }
  its('stdout') { should match(/lbmethod_byrequests_module/) }
end

describe command('httpd -M'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/proxy_module/) }
  its('stdout') { should match(/proxy_http_module/) }
  its('stdout') { should match(/rewrite_module/) }
  its('stdout') { should match(/proxy_balancer_module/) }
  its('stdout') { should match(/lbmethod_byrequests_module/) }
end

# Check if module configuration allows the server to start
describe command('apache2ctl configtest'), if: os.debian? || os.ubuntu? do
  its('stdout') { should match(/Syntax OK/) }
  its('exit_status') { should eq 0 }
end

describe command('httpd -t'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('stdout') { should match(/Syntax OK/) }
  its('exit_status') { should eq 0 }
end

# Verify security settings for modules
describe apache_conf('/etc/apache2/mods-enabled/proxy.conf'), if: os.debian? || os.ubuntu? do
  its('content') { should match(/<Proxy \*>/) }
  its('content') { should match(/Require all denied/) }
end

describe file('/etc/httpd/conf.d/proxy.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/<Proxy \*>/) }
  its('content') { should match(/Require all denied/) }
end
