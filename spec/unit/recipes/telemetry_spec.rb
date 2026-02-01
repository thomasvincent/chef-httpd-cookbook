# frozen_string_literal: true

require 'spec_helper'

describe 'httpd::telemetry' do
  context 'when telemetry is disabled' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04') do |node|
        node.normal['httpd']['telemetry']['enabled'] = false
      end.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end

  context 'when telemetry is enabled with prometheus' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04') do |node|
        node.normal['httpd']['telemetry']['enabled'] = true
        node.normal['httpd']['telemetry']['prometheus']['enabled'] = true
        node.normal['httpd']['telemetry']['grafana']['enabled'] = false
      end
      allow_any_instance_of(Chef::Recipe).to receive(:configure_prometheus_exporter).and_return(true)
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'enables server-status' do
      expect(chef_run.node['httpd']['security']['disable_server_status']).to eq(false)
    end

    it 'restricts server-status access' do
      expect(chef_run.node['httpd']['monitoring']['restricted_access']).to eq(true)
    end
  end

  context 'when telemetry is enabled with prometheus and grafana' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04') do |node|
        node.normal['httpd']['telemetry']['enabled'] = true
        node.normal['httpd']['telemetry']['prometheus']['enabled'] = true
        node.normal['httpd']['telemetry']['grafana']['enabled'] = true
        node.normal['httpd']['telemetry']['grafana']['url'] = 'http://grafana:3000'
        node.normal['httpd']['telemetry']['grafana']['datasource'] = 'Prometheus'
      end
      allow_any_instance_of(Chef::Recipe).to receive(:configure_prometheus_exporter).and_return(true)
      allow_any_instance_of(Chef::Recipe).to receive(:configure_grafana_dashboard).and_return(true)
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
