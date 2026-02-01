# frozen_string_literal: true

require 'spec_helper'

describe 'test::httpd_config' do
  platforms = {
    'ubuntu' => {
      'versions' => ['20.04'],
      'conf_available_dir' => '/etc/apache2/conf-available',
      'conf_enabled_dir' => '/etc/apache2/conf-enabled',
    },
    'centos' => {
      'versions' => %w(8),
      'conf_available_dir' => '/etc/httpd/conf.available',
      'conf_enabled_dir' => '/etc/httpd/conf.d',
    },
  }

  platforms.each do |platform, platform_info|
    platform_info['versions'].each do |version|
      context "on #{platform} #{version}" do
        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(
            step_into: ['httpd_config'],
            platform: platform,
            version: version
          )
          runner.node.default['httpd']['conf_available_dir'] = platform_info['conf_available_dir']
          runner.node.default['httpd']['conf_enabled_dir'] = platform_info['conf_enabled_dir']
          runner.converge('test::httpd_config')
        end

        context 'with content property' do
          it 'creates the config file with specified content' do
            config_path = if platform == 'centos'
                            "#{platform_info['conf_enabled_dir']}/test-config.conf"
                          else
                            "#{platform_info['conf_available_dir']}/test-config.conf"
                          end

            expect(chef_run).to create_file(config_path).with(
              content: "# Test config\nServerName localhost\n",
              owner: 'root',
              group: 'root',
              mode: '0644'
            )
          end
        end

        context 'with source property' do
          it 'creates the config file from template' do
            config_path = if platform == 'centos'
                            "#{platform_info['conf_enabled_dir']}/template-config.conf"
                          else
                            "#{platform_info['conf_available_dir']}/template-config.conf"
                          end

            expect(chef_run).to create_template(config_path).with(
              source: 'security.conf.erb',
              cookbook: 'httpd',
              owner: 'root',
              group: 'root',
              mode: '0644'
            )
          end
        end

        next unless platform == 'ubuntu'

        context 'with enabled config on Debian' do
          it 'creates a symlink in the conf-enabled directory' do
            expect(chef_run).to create_link("#{platform_info['conf_enabled_dir']}/test-config.conf").with(
              to: "#{platform_info['conf_available_dir']}/test-config.conf"
            )

            expect(chef_run).to create_link("#{platform_info['conf_enabled_dir']}/template-config.conf").with(
              to: "#{platform_info['conf_available_dir']}/template-config.conf"
            )
          end
        end

        context 'when disabling a config on Debian' do
          it 'does not create a symlink for disabled config' do
            # The disabled config has enable: false, so delete_symlink is called
            # but with only_if guard that checks file existence (which won't exist in test)
            # So the link resource exists but may not execute
            expect(chef_run).not_to create_link("#{platform_info['conf_enabled_dir']}/disabled-config.conf")
          end
        end
      end
    end
  end
end
