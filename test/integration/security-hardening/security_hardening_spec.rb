# frozen_string_literal: true

# Security Hardening Test Suite
# Validates that Apache is properly hardened with security best practices

title 'Security Hardening Tests'

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

# Basic security configuration
describe apache_conf, if: os.debian? || os.ubuntu? do
  its('ServerTokens') { should eq 'Prod' }
  its('ServerSignature') { should eq 'Off' }
  its('TraceEnable') { should eq 'Off' }
end

describe apache_conf, if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('ServerTokens') { should eq 'Prod' }
  its('ServerSignature') { should eq 'Off' }
  its('TraceEnable') { should eq 'Off' }
end

# File permissions for critical files
describe file('/etc/apache2/apache2.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('mode') { should cmp '0640' }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
end

describe file('/etc/httpd/conf/httpd.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('mode') { should cmp '0640' }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
end

# SSL certificate permissions
describe file('/etc/pki/tls/private/localhost.key'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('mode') { should cmp '0600' }
  its('owner') { should eq 'root' }
end

describe file('/etc/ssl/private/localhost.key'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('mode') { should cmp '0600' }
  its('owner') { should eq 'root' }
end

# Security module enablement
describe apache_conf('/etc/apache2/mods-enabled/headers.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
end

# Security Headers
describe http('https://localhost', ssl_verify: false) do
  its('headers.X-XSS-Protection') { should eq '1; mode=block' }
  its('headers.X-Content-Type-Options') { should eq 'nosniff' }
  its('headers.X-Frame-Options') { should eq 'SAMEORIGIN' }
  its('headers.Referrer-Policy') { should eq 'strict-origin-when-cross-origin' }
  its('headers.Content-Security-Policy') { should include "default-src 'self'" }
  its('headers.Permissions-Policy') { should include 'geolocation=()' }
end

# HSTS for HTTPS sites
describe http('https://localhost', ssl_verify: false) do
  its('headers.Strict-Transport-Security') { should include 'max-age=31536000' }
end

# TLS Configuration
describe ssl(port: 443).protocols('ssl3') do
  it { should_not be_enabled }
end

describe ssl(port: 443).protocols('tls1.0') do
  it { should_not be_enabled }
end

describe ssl(port: 443).protocols('tls1.1') do
  it { should_not be_enabled }
end

describe ssl(port: 443).protocols('tls1.2') do
  it { should be_enabled }
end

describe ssl(port: 443).protocols('tls1.3') do
  it { should be_enabled }
end

# Cipher configuration
describe ssl(port: 443).ciphers('ADH') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('NULL') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('EXPORT') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('RC4') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('DES') do
  it { should_not be_enabled }
end

# Validate that modern ciphers are enabled
describe ssl(port: 443).ciphers('TLS_AES_256_GCM_SHA384') do
  it { should be_enabled }
end

# ModSecurity / WAF (if applicable)
describe file('/etc/apache2/mods-available/security2.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/etc/httpd/conf.d/mod_security.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
end

# Automated scanner detection / IP blacklisting
describe file('/etc/apache2/conf-enabled/security.conf'), if: os.debian? || os.ubuntu? do
  its('content') { should match /LimitRequestFields/ }
  its('content') { should match /LimitRequestFieldSize/ }
  its('content') { should match /LimitRequestBody/ }
end

describe file('/etc/httpd/conf.d/security.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match /LimitRequestFields/ }
  its('content') { should match /LimitRequestFieldSize/ }
  its('content') { should match /LimitRequestBody/ }
end

# Directory access controls
describe apache_conf('/etc/apache2/conf-enabled/security.conf'), if: os.debian? || os.ubuntu? do
  its('params') { should include('<Directory />' => 'Options None') }
  its('params') { should include('<Directory />' => 'AllowOverride None') }
  its('params') { should include('<Directory />' => 'Require all denied') }
end

describe apache_conf('/etc/httpd/conf.d/security.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('params') { should include('<Directory />' => 'Options None') }
  its('params') { should include('<Directory />' => 'AllowOverride None') }
  its('params') { should include('<Directory />' => 'Require all denied') }
end
