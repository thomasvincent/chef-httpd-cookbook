# frozen_string_literal: true

require 'spec_helper'

describe 'httpd::install' do
  platforms = {
    'ubuntu' => {
      'versions' => ['20.04', '22.04'],
      'package_name' => 'apache2',
      'service_name' => 'apache2',
    },
    'centos' => {
      'versions' => %w(8 9),
      'package_name' => 'httpd',
      'service_name' => 'httpd',
    },
  }

  platforms.each do |platform, platform_info|
    platform_info['versions'].each do |version|
      context "On #{platform} #{version}" do
        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(platform: platform, version: version)
          runner.converge(described_recipe)
        end

        it 'converges successfully' do
          expect { chef_run }.to_not raise_error
        end

        it 'creates the httpd_install resource' do
          expect(chef_run).to install_httpd_install('default')
        end
      end
    end
  end
end
