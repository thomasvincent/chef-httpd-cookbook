# frozen_string_literal: true

# Telemetry Test Suite
# Validates the monitoring and metrics functionality of Apache HTTP Server

title 'Apache Telemetry Tests'

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

# Verify Apache mod_status is enabled (required for basic metrics)
describe apache_conf('/etc/apache2/mods-enabled/status.load'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  it { should be_symlink }
end

describe file('/etc/httpd/conf.modules.d/00-base.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/LoadModule status_module/) }
end

# Check server-status configuration
describe file('/etc/apache2/mods-enabled/status.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/SetHandler server-status/) }
end

describe file('/etc/httpd/conf.d/status.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/SetHandler server-status/) }
end

# Verify Prometheus exporter configuration
describe file('/etc/apache2/conf-enabled/prometheus.conf'), :if => os.debian? || os.ubuntu? do
  it { should exist }
  its('content') { should match(/PrometheusExporterEnabled On/) }
  its('content') { should match(/PrometheusExporterPath "\/metrics"/) }
end

describe file('/etc/httpd/conf.d/prometheus.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  it { should exist }
  its('content') { should match(/PrometheusExporterEnabled On/) }
  its('content') { should match(/PrometheusExporterPath "\/metrics"/) }
end

# Check for Prometheus apache exporter service
describe service('apache-exporter'), :if => os.linux? do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# Verify exporter systemd unit file
describe file('/etc/systemd/system/apache-exporter.service'), :if => os.linux? do
  it { should exist }
  its('content') { should match(/ExecStart=\/usr\/local\/bin\/apache_exporter/) }
end

# Test metrics endpoint accessibility
describe http('http://localhost/metrics') do
  its('status') { should eq 200 }
  its('body') { should match(/apache_/) }
end

# Test server-status endpoint (should be restricted)
describe http('http://localhost/server-status') do
  its('status') { should eq 403 }  # Publicly forbidden, only accessible to restricted IPs
end

describe http('http://localhost/server-status', :params => {'auto' => ''}) do
  its('status') { should eq 403 }  # Publicly forbidden, only accessible to restricted IPs
end

# Validate metric format and content
describe http('http://localhost/metrics') do
  its('body') { should match(/apache_connections/) }
  its('body') { should match(/apache_workers/) }
  its('body') { should match(/apache_scoreboard/) }
  its('body') { should match(/apache_cpu/) }
  its('body') { should match(/apache_requests/) }
  its('body') { should match(/apache_up/) }
  its('body') { should match(/apache_uptime_seconds_total/) }
end

# Check Grafana integration settings
describe file('/etc/grafana/provisioning/dashboards/apache.yaml'), :if => os.linux? do
  it { should exist }
  its('content') { should match(/name: 'Apache Dashboard'/) }
end

describe file('/etc/grafana/provisioning/datasources/prometheus.yaml'), :if => os.linux? do
  it { should exist }
  its('content') { should match(/name: Prometheus/) }
  its('content') { should match(/type: prometheus/) }
end

# Test monitoring endpoint security
describe apache_conf('/etc/apache2/conf-enabled/prometheus.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match(/<Location "\/metrics">/) }
  its('content') { should match(/Require ip/) }
end

describe file('/etc/httpd/conf.d/prometheus.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/<Location "\/metrics">/) }
  its('content') { should match(/Require ip/) }
end

# Verify exporter configuration
describe file('/etc/apache_exporter/apache_exporter.yaml'), :if => os.linux? do
  it { should exist }
  its('content') { should match(/scrape_uri/) }
  its('content') { should match(/telemetry_path/) }
end

# Check port for Prometheus exporter
describe port(9117) do
  it { should be_listening }
  its('processes') { should include 'apache_exporter' }
end

# Test custom metrics (if configured)
describe file('/etc/apache2/conf-enabled/prometheus.conf'), :if => os.debian? || os.ubuntu? do
  its('content') { should match(/PrometheusExporterCustomMetric/) }
end

describe file('/etc/httpd/conf.d/prometheus.conf'), :if => os.redhat? || os.name == 'amazon' || os.name == 'fedora' do
  its('content') { should match(/PrometheusExporterCustomMetric/) }
end

# Verify local Prometheus configuration (if present)
describe file('/etc/prometheus/prometheus.yml'), :if => os.linux? do
  its('content') { should match(/job_name: 'apache'/) }
end

# Check that metrics are properly typed
describe http('http://localhost/metrics') do
  its('body') { should match(/HELP apache_/) }  # Help text for metrics
  its('body') { should match(/TYPE apache_/) }  # Type information for metrics
end

# Test that custom telemetry path works (if configured)
describe http('http://localhost/telemetry') do
  its('status') { should eq 200 }
  its('body') { should match(/apache_/) }
end

# Verify overall Apache performance with metrics
describe http('http://localhost/') do
  its('status') { should eq 200 }
end

# After HTTP request, check metrics update
describe command('curl -s http://localhost/metrics | grep "apache_requests_total"') do
  its('stdout') { should match(/apache_requests_total/) }
  its('exit_status') { should eq 0 }
end

