# frozen_string_literal: true

# SSL/TLS Configuration Test Suite
# Validates the SSL/TLS configuration and security settings of Apache HTTP Server

title 'Apache SSL/TLS Configuration Tests'

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

# Test SSL module enabled
describe apache_conf('/etc/apache2/mods-enabled/ssl.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_symlink }
end

describe file('/etc/httpd/conf.modules.d/00-ssl.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/LoadModule ssl_module/) }
end

# Verify certificate configuration
describe file('/etc/pki/tls/certs/localhost.crt'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('mode') { should cmp '0644' }
end

describe file('/etc/ssl/certs/localhost.crt'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('mode') { should cmp '0644' }
end

describe file('/etc/pki/tls/private/localhost.key'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('mode') { should cmp '0600' }
end

describe file('/etc/ssl/private/localhost.key'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('mode') { should cmp '0600' }
end

# Check SSL configuration
describe apache_conf('/etc/apache2/mods-enabled/ssl.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match(/SSLEngine on/) }
  its('content') { should match(/SSLProtocol/) }
  its('content') { should match(/SSLCipherSuite/) }
  its('content') { should match(/SSLHonorCipherOrder on/) }
end

describe file('/etc/httpd/conf.d/ssl.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/SSLEngine on/) }
  its('content') { should match(/SSLProtocol/) }
  its('content') { should match(/SSLCipherSuite/) }
  its('content') { should match(/SSLHonorCipherOrder on/) }
end

# Test SSL/TLS protocol support
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

# Check cipher suite settings
describe ssl(port: 443).ciphers('TLS_AES_256_GCM_SHA384') do
  it { should be_enabled }
end

describe ssl(port: 443).ciphers('TLS_CHACHA20_POLY1305_SHA256') do
  it { should be_enabled }
end

describe ssl(port: 443).ciphers('NULL') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('aNULL') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('DES') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('3DES') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('RC4') do
  it { should_not be_enabled }
end

describe ssl(port: 443).ciphers('MD5') do
  it { should_not be_enabled }
end

# Validate HSTS implementation
describe http('https://localhost/', ssl_verify: false) do
  its('headers.Strict-Transport-Security') { should match(/max-age=/) }
end

# Check security headers
describe http('https://localhost/', ssl_verify: false) do
  its('headers.X-Content-Type-Options') { should eq 'nosniff' }
  its('headers.X-XSS-Protection') { should match(/1; mode=block/) }
  its('headers.X-Frame-Options') { should eq 'SAMEORIGIN' }
end

# Test SSL/TLS redirection
describe http('http://localhost/') do
  its('status') { should eq 301 }
  its('headers.Location') { should match(/^https:/) }
end

# Verify SSL session handling
describe apache_conf('/etc/apache2/mods-enabled/ssl.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match(/SSLSessionCache/) }
  its('content') { should match(/SSLSessionTickets/) }
  its('content') { should match(/SSLSessionTimeout/) }
end

describe file('/etc/httpd/conf.d/ssl.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/SSLSessionCache/) }
  its('content') { should match(/SSLSessionTickets/) }
  its('content') { should match(/SSLSessionTimeout/) }
end

# Test OCSP stapling
describe apache_conf('/etc/apache2/mods-enabled/ssl.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match(/SSLUseStapling/) }
  its('content') { should match(/SSLStaplingCache/) }
end

describe file('/etc/httpd/conf.d/ssl.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/SSLUseStapling/) }
  its('content') { should match(/SSLStaplingCache/) }
end

# Verify HTTP/2 support with SSL
describe apache_conf('/etc/apache2/mods-enabled/http2.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/etc/httpd/conf.modules.d/00-http2.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/LoadModule http2_module/) }
end

# Test for secure SSL/TLS configuration using external tools
describe command('curl -s -I --tlsv1.3 https://localhost/ -k') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/HTTP\/[1-2]/) }
end

# Verify port 443 is listening
describe port(443) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

# Test SSL configuration syntax
describe command('apache2ctl -t'), :if => os.debian? || os.ubuntu? do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

describe command('httpd -t'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/Syntax OK/) }
end

