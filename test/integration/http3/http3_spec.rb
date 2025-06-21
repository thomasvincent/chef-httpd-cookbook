# frozen_string_literal: true

# HTTP/3 Configuration Test Suite
# Validates that Apache is configured properly for HTTP/3 support

title 'HTTP/3 Configuration Tests'

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

# HTTP/3 module installation
describe file('/etc/apache2/mods-available/quic.load'), if: os.debian? || os.ubuntu? do
  it { should exist }
end

describe file('/etc/apache2/mods-available/quic.conf'), if: os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match /H3Direct\s+on/ }
end

describe file('/etc/httpd/modules/mod_quic.so'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
end

# HTTP/3 module enablement
describe file('/etc/apache2/mods-enabled/quic.load'), if: os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_symlink }
end

# TLS Configuration for HTTP/3
describe apache_conf('/etc/apache2/sites-enabled/000-default-ssl.conf'), if: os.debian? || os.ubuntu? do
  its('params') { should include('Protocols' => 'h2 h3') }
  its('params') { should include('H3Direct' => 'on') }
  its('params') { should include('Alt-Svc' => 'h3=":443"; ma=86400') }
end

describe apache_conf('/etc/httpd/conf.d/ssl.conf'), if: os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('params') { should include('Protocols' => 'h2 h3') }
  its('params') { should include('H3Direct' => 'on') }
  its('params') { should include('Alt-Svc' => 'h3=":443"; ma=86400') }
end

# TLS configuration
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

# HTTP/3 service availability
describe port(443) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
  its('protocols') { should include 'udp' } # HTTP/3 uses QUIC which runs over UDP
end

# HTTP/3 Alt-Svc header validation
describe http('https://localhost', ssl_verify: false) do
  its('headers.Alt-Svc') { should match /h3=":443"; ma=86400/ }
end
