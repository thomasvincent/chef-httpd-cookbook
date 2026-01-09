# frozen_string_literal: true

# InSpec test for recipe httpd::ssl

describe package('openssl') do
  it { should be_installed }
end

describe file('/etc/apache2/conf-available/ssl-hardening.conf') do
  it { should exist }
  its('content') { should match(/SSLProtocol/) }
  its('content') { should match(/TLSv1\.2/) }
  its('content') { should match(/SSLCipherSuite/) }
end

describe command('apache2ctl -M') do
  its('stdout') { should match(/ssl_module/) }
end

describe port(443) do
  it { should be_listening }
end
