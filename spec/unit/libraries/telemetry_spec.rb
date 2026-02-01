# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/telemetry'

describe 'Httpd::Telemetry' do
  let(:dummy_class) { Class.new { include Httpd::Telemetry } }
  let(:telemetry) { dummy_class.new }
  let(:node) { Chef::Node.new }

  before do
    allow(telemetry).to receive(:node).and_return(node)
    allow(Chef::Log).to receive(:info)
    allow(Chef::Log).to receive(:warn)
    allow(Chef::Log).to receive(:error)
  end

  describe '#configure_prometheus_exporter' do
    context 'when built-in module is available' do
      before do
        allow(telemetry).to receive(:apache_has_prometheus_module?).and_return(true)
        allow(telemetry).to receive(:configure_builtin_prometheus_exporter).and_return(true)
      end

      it 'uses the built-in exporter' do
        expect(telemetry).to receive(:configure_builtin_prometheus_exporter)
        expect(telemetry).not_to receive(:configure_external_prometheus_exporter)
        result = telemetry.configure_prometheus_exporter
        expect(result).to be true
      end
    end

    context 'when built-in module is not available' do
      before do
        allow(telemetry).to receive(:apache_has_prometheus_module?).and_return(false)
        allow(telemetry).to receive(:configure_external_prometheus_exporter).and_return(true)
      end

      it 'uses the external exporter' do
        expect(telemetry).not_to receive(:configure_builtin_prometheus_exporter)
        expect(telemetry).to receive(:configure_external_prometheus_exporter)
        result = telemetry.configure_prometheus_exporter
        expect(result).to be true
      end
    end

    it 'passes correct default metrics' do
      allow(telemetry).to receive(:apache_has_prometheus_module?).and_return(true)
      expected_metrics = %w(connections scoreboard cpu requests throughput response_time workers)
      expect(telemetry).to receive(:configure_builtin_prometheus_exporter).with(
        '/server-status?auto', '/metrics', expected_metrics
      ).and_return(true)
      telemetry.configure_prometheus_exporter
    end
  end

  describe '#apache_has_prometheus_module?' do
    context 'on Debian systems' do
      before do
        allow(telemetry).to receive(:platform_family?).with('debian').and_return(true)
      end

      it 'checks the correct file paths' do
        allow(::File).to receive(:exist?).and_call_original
        expect(::File).to receive(:exist?).with('/usr/lib/apache2/modules/mod_prometheus_exporter.so').and_return(false)
        expect(::File).to receive(:exist?).with('/usr/lib/apache2/modules/mod_prometheus.so').and_return(true)
        result = telemetry.apache_has_prometheus_module?
        expect(result).to be true
      end

      it 'returns false if no module files are found' do
        allow(::File).to receive(:exist?).and_call_original
        expect(::File).to receive(:exist?).with('/usr/lib/apache2/modules/mod_prometheus_exporter.so').and_return(false)
        expect(::File).to receive(:exist?).with('/usr/lib/apache2/modules/mod_prometheus.so').and_return(false)
        result = telemetry.apache_has_prometheus_module?
        expect(result).to be false
      end

      it 'handles errors gracefully' do
        allow(::File).to receive(:exist?).and_call_original
        expect(::File).to receive(:exist?).with('/usr/lib/apache2/modules/mod_prometheus_exporter.so').and_raise(StandardError, 'Test error')
        result = telemetry.apache_has_prometheus_module?
        expect(result).to be false
      end
    end

    context 'on RHEL systems' do
      before do
        allow(telemetry).to receive(:platform_family?).with('debian').and_return(false)
      end

      it 'checks the correct file paths' do
        allow(::File).to receive(:exist?).and_call_original
        expect(::File).to receive(:exist?).with('/usr/lib64/httpd/modules/mod_prometheus_exporter.so').and_return(true)
        result = telemetry.apache_has_prometheus_module?
        expect(result).to be true
      end
    end
  end

  describe '#configure_builtin_prometheus_exporter' do
    before do
      allow(telemetry).to receive(:httpd_module).and_return(nil)
      allow(telemetry).to receive(:httpd_config).and_return(nil)
      allow(telemetry).to receive(:configure_server_status).and_return(true)
    end

    it 'calls httpd_module for prometheus_exporter' do
      expect(telemetry).to receive(:httpd_module).with('prometheus_exporter')
      telemetry.configure_builtin_prometheus_exporter('/server-status?auto', '/metrics', ['connections'])
    end

    it 'calls httpd_config for prometheus-exporter' do
      expect(telemetry).to receive(:httpd_config).with('prometheus-exporter')
      telemetry.configure_builtin_prometheus_exporter('/server-status?auto', '/metrics', ['connections'])
    end

    it 'configures server-status module' do
      expect(telemetry).to receive(:configure_server_status)
      telemetry.configure_builtin_prometheus_exporter('/server-status?auto', '/metrics', ['connections'])
    end

    it 'returns true on success' do
      result = telemetry.configure_builtin_prometheus_exporter('/server-status?auto', '/metrics', ['connections'])
      expect(result).to be true
    end

    it 'handles errors gracefully' do
      allow(telemetry).to receive(:httpd_config).and_raise(StandardError, 'Test error')
      result = telemetry.configure_builtin_prometheus_exporter('/server-status?auto', '/metrics', ['connections'])
      expect(result).to be false
    end
  end

  describe '#configure_external_prometheus_exporter' do
    context 'with package installation' do
      before do
        allow(telemetry).to receive(:platform_family?).with('debian').and_return(true)
        allow(telemetry).to receive(:platform_family?).with('rhel').and_return(false)
        allow(telemetry).to receive(:package).and_return(nil)
        allow(telemetry).to receive(:template).and_return(nil)
        allow(telemetry).to receive(:execute).and_return(nil)
        allow(telemetry).to receive(:service).and_return(nil)
        allow(telemetry).to receive(:configure_server_status).and_return(true)
      end

      it 'installs the appropriate package' do
        expect(telemetry).to receive(:package).with('prometheus-apache-exporter')
        telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
      end

      it 'creates the systemd service file' do
        expect(telemetry).to receive(:template).with('/etc/systemd/system/apache-exporter.service')
        telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
      end

      it 'enables and starts the service' do
        expect(telemetry).to receive(:service).with('apache-exporter')
        telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
      end

      it 'configures server-status module' do
        expect(telemetry).to receive(:configure_server_status)
        telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
      end

      it 'returns true on success' do
        result = telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
        expect(result).to be true
      end

      it 'handles errors gracefully' do
        allow(telemetry).to receive(:package).and_raise(StandardError, 'Test error')
        result = telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
        expect(result).to be false
      end
    end

    context 'with binary installation' do
      before do
        allow(telemetry).to receive(:platform_family?).and_return(false)
        allow(telemetry).to receive(:remote_file).and_return(nil)
        allow(telemetry).to receive(:template).and_return(nil)
        allow(telemetry).to receive(:execute).and_return(nil)
        allow(telemetry).to receive(:service).and_return(nil)
        allow(telemetry).to receive(:configure_server_status).and_return(true)
      end

      it 'downloads the binary' do
        expect(telemetry).to receive(:remote_file).with('/usr/local/bin/apache_exporter')
        telemetry.configure_external_prometheus_exporter(nil, '/server-status?auto', '/metrics', nil)
      end
    end
  end

  describe '#configure_server_status' do
    before do
      allow(telemetry).to receive(:httpd_module).and_return(nil)
      allow(telemetry).to receive(:httpd_config).and_return(nil)
    end

    it 'enables the status module' do
      expect(telemetry).to receive(:httpd_module).with('status')
      telemetry.configure_server_status
    end

    it 'creates the server-status configuration' do
      expect(telemetry).to receive(:httpd_config).with('server-status')
      telemetry.configure_server_status
    end

    it 'returns true on success' do
      result = telemetry.configure_server_status
      expect(result).to be true
    end

    it 'handles errors gracefully' do
      allow(telemetry).to receive(:httpd_config).and_raise(StandardError, 'Test error')
      result = telemetry.configure_server_status
      expect(result).to be false
    end
  end

  describe '#configure_grafana_dashboard' do
    before do
      allow(telemetry).to receive(:platform_family?).with('debian').and_return(false)
      allow(telemetry).to receive(:file).and_return(nil)
    end

    it 'creates a dashboard JSON file' do
      expect(telemetry).to receive(:file).with('/etc/httpd/grafana-dashboard.json')
      telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus')
    end

    it 'uses the correct path based on platform' do
      allow(telemetry).to receive(:platform_family?).with('debian').and_return(true)
      expect(telemetry).to receive(:file).with('/etc/apache2/grafana-dashboard.json')
      telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus')
    end

    context 'with API key provided' do
      let(:http) { double('http') }
      let(:response) { double('response') }

      before do
        allow(URI).to receive(:parse).and_return(
          double('uri', host: 'grafana', port: 3000, scheme: 'http', request_uri: '/api/dashboards/db')
        )
        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(Net::HTTP::Post).to receive(:new).and_return(double('request', :[]= => nil, :body= => nil))
        allow(http).to receive(:use_ssl=)
        allow(http).to receive(:request).and_return(response)
      end

      it 'attempts to upload dashboard via API' do
        allow(response).to receive(:code).and_return('200')
        result = telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus', 'api-key')
        expect(result).to be true
      end

      it 'handles API errors gracefully' do
        allow(response).to receive(:code).and_return('400')
        allow(response).to receive(:body).and_return('Error message')
        result = telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus', 'api-key')
        expect(result).to be false
      end

      it 'handles HTTP errors gracefully' do
        allow(http).to receive(:request).and_raise(StandardError, 'Connection error')
        result = telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus', 'api-key')
        expect(result).to be false
      end
    end

    it 'returns true when API key is not provided' do
      result = telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus')
      expect(result).to be true
    end

    it 'handles errors gracefully' do
      allow(telemetry).to receive(:file).and_raise(StandardError, 'Test error')
      result = telemetry.configure_grafana_dashboard('http://grafana:3000', 'prometheus')
      expect(result).to be false
    end
  end
end
