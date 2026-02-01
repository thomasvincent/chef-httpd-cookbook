# frozen_string_literal: true

require 'spec_helper'

describe 'test::httpd_vhost' do
  platforms = {
    'ubuntu' => {
      'versions' => ['20.04'],
      'conf_available_dir' => '/etc/apache2/conf-available',
      'conf_enabled_dir' => '/etc/apache2/conf-enabled',
      'user' => 'www-data',
      'group' => 'www-data',
    },
    'centos' => {
      'versions' => %w(8),
      'conf_available_dir' => '/etc/httpd/conf.available',
      'conf_enabled_dir' => '/etc/httpd/conf.d',
      'user' => 'apache',
      'group' => 'apache',
    },
  }

  platforms.each do |platform, platform_info|
    platform_info['versions'].each do |version|
      context "on #{platform} #{version}" do
        before do
          allow(::File).to receive(:exist?).and_call_original
          allow(::File).to receive(:exist?).with("#{platform_info['conf_enabled_dir']}/20-disabled.com.conf").and_return(true)
        end

        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(
            step_into: ['httpd_vhost'],
            platform: platform,
            version: version
          )
          runner.node.default['httpd']['conf_available_dir'] = platform_info['conf_available_dir']
          runner.node.default['httpd']['conf_enabled_dir'] = platform_info['conf_enabled_dir']
          runner.node.default['httpd']['user'] = platform_info['user']
          runner.node.default['httpd']['group'] = platform_info['group']
          runner.converge('test::httpd_vhost')
        end

        context 'creates a basic virtual host' do
          it 'creates the document root directory' do
            expect(chef_run).to create_directory('/var/www/example.com').with(
              owner: platform_info['user'],
              group: platform_info['group'],
              mode: '0755',
              recursive: true
            )
          end

          it 'creates the virtual host configuration file' do
            config_path = "#{platform_info['conf_available_dir']}/10-example.com.conf"
            expect(chef_run).to create_template(config_path).with(
              source: 'vhost.conf.erb',
              cookbook: 'httpd',
              owner: 'root',
              group: 'root',
              mode: '0644'
            )
          end

          it 'enables the virtual host via symlink' do
            expect(chef_run).to create_link("#{platform_info['conf_enabled_dir']}/10-example.com.conf").with(
              to: "#{platform_info['conf_available_dir']}/10-example.com.conf"
            )
          end
        end

        context 'creates an SSL-enabled virtual host' do
          it 'creates the document root directory' do
            expect(chef_run).to create_directory('/var/www/secure.example.com').with(
              owner: platform_info['user'],
              group: platform_info['group'],
              mode: '0755',
              recursive: true
            )
          end

          it 'creates the SSL directory for the certificate' do
            expect(chef_run).to create_directory('/etc/ssl/certs').with(recursive: true)
          end

          it 'creates the SSL directory for the key' do
            expect(chef_run).to create_directory('/etc/ssl/private').with(recursive: true)
          end

          it 'creates the virtual host configuration file with SSL settings' do
            config_path = "#{platform_info['conf_available_dir']}/10-secure.example.com.conf"
            expect(chef_run).to create_template(config_path)
          end
        end

        context 'when disabling a virtual host' do
          it 'removes the enabled symlink for disabled vhost' do
            expect(chef_run).to delete_link("#{platform_info['conf_enabled_dir']}/20-disabled.com.conf")
          end
        end
      end
    end
  end
end
