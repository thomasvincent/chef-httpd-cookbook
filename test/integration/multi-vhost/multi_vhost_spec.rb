# frozen_string_literal: true

# Multi-VHost Test Suite
# Validates the configuration and functionality of multiple Apache virtual hosts

title 'Apache Multi-VHost Tests'

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

# Virtual host configuration files
describe file('/etc/apache2/sites-enabled/example.com.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/ServerName example.com/) }
  its('content') { should match(/DocumentRoot \/var\/www\/example/) }
  its('content') { should match(/Listen 8080/) }
end

describe file('/etc/httpd/conf.d/example.com.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/ServerName example.com/) }
  its('content') { should match(/DocumentRoot \/var\/www\/example/) }
  its('content') { should match(/Listen 8080/) }
end

# Secure virtual host configuration
describe file('/etc/apache2/sites-enabled/secure.example.com.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/ServerName secure.example.com/) }
  its('content') { should match(/DocumentRoot \/var\/www\/secure/) }
  its('content') { should match(/SSLEngine on/) }
  its('content') { should match(/SSLCertificateFile/) }
  its('content') { should match(/SSLCertificateKeyFile/) }
end

describe file('/etc/httpd/conf.d/secure.example.com.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/ServerName secure.example.com/) }
  its('content') { should match(/DocumentRoot \/var\/www\/secure/) }
  its('content') { should match(/SSLEngine on/) }
  its('content') { should match(/SSLCertificateFile/) }
  its('content') { should match(/SSLCertificateKeyFile/) }
end

# Document root permissions
describe file('/var/www/example'), :if => os.linux? do
  it { should exist }
  it { should be_directory }
  its('owner') { should eq 'root' }
  its('mode') { should cmp '0755' }
end

describe file('/var/www/secure'), :if => os.linux? do
  it { should exist }
  it { should be_directory }
  its('owner') { should eq 'root' }
  its('mode') { should cmp '0755' }
end

# Default document existence
describe file('/var/www/example/index.html'), :if => os.linux? do
  it { should exist }
  it { should be_file }
  its('content') { should match(/Welcome to example.com/) }
end

describe file('/var/www/secure/index.html'), :if => os.linux? do
  it { should exist }
  it { should be_file }
  its('content') { should match(/Welcome to secure.example.com/) }
end

# Port bindings
describe port(80) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

describe port(8080) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

describe port(443) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

# HTTP responses for each virtual host
describe http('http://localhost:8080/', enable_remote_worker: true) do
  its('status') { should eq 200 }
  its('body') { should match(/Welcome to example.com/) }
end

describe http('https://localhost/', enable_remote_worker: true, ssl_verify: false) do
  its('status') { should eq 200 }
  its('body') { should match(/Welcome to secure.example.com/) }
end

# Virtual host specific logging
describe file('/var/log/apache2/example.com-access.log'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/var/log/apache2/secure.example.com-access.log'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/var/log/httpd/example.com-access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
end

describe file('/var/log/httpd/secure.example.com-access_log'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
end

# Check for name-based virtual hosting
describe apache_conf, :if => os.debian? || os.ubuntu? do
  its('NameVirtualHost') { should include '*:80' }
end

describe apache_conf, :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('NameVirtualHost') { should include '*:80' }
end

# SSL configuration for secure vhost
describe ssl(port: 443) do
  it { should be_enabled }
end

describe ssl(port: 443).protocols('tls1.2') do
  it { should be_enabled }
end

describe ssl(port: 443).ciphers('TLS_AES_256_GCM_SHA384') do
  it { should be_enabled }
end

# Check Apache syntax for virtual hosts
describe command('apache2ctl -t'), :if => os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

describe command('httpd -t'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

# Server alias configuration
describe apache_conf('/etc/apache2/sites-enabled/example.com.conf'), :if => os.debian? || os.ubuntu? do
  its('ServerAlias') { should include 'www.example.com' }
end

describe apache_conf('/etc/httpd/conf.d/example.com.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('ServerAlias') { should include 'www.example.com' }
end

