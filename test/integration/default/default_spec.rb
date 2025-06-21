# frozen_string_literal: true

# Default Test Suite
# Validates the basic installation and configuration of Apache HTTP Server

title 'Default Apache Installation & Configuration Tests'

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

# Check main configuration file
describe file('/etc/apache2/apache2.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_file }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0644' }
end

describe file('/etc/httpd/conf/httpd.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  it { should be_file }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('mode') { should cmp '0644' }
end

# Verify Apache port is listening
describe port(80) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

# Check Apache default page or server response
describe http('http://localhost/') do
  its('status') { should eq 200 }
end

# Check default virtual host configuration
describe file('/etc/apache2/sites-enabled/000-default.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/DocumentRoot/) }
end

describe file('/etc/httpd/conf.d/welcome.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
end

# Check for a default MPM loaded
describe apache_conf('/etc/apache2/mods-enabled/mpm_prefork.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe apache_conf('/etc/httpd/conf.modules.d/00-mpm.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/LoadModule mpm/) }
end

# Verify error and access logs
describe file('/var/log/apache2/error.log'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('owner') { should eq 'root' }
end

describe file('/var/log/httpd/error_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('owner') { should eq 'root' }
end

