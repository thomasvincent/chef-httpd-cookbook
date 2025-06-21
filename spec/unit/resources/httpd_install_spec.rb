# frozen_string_literal: true

require 'spec_helper'

describe 'test::httpd_install' do
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

  before do
    stub_command('getenforce | grep -i disabled').and_return(false)
    stub_command('sestatus | grep -q "SELinux status: enabled"').and_return(true)
    stub_command('semanage port -l | grep -w \'http_port_t\' | grep -w 80').and_return(false)
    stub_command('getsebool httpd_can_network_connect_http | grep -q "on$"').and_return(false)
    stub_command('getsebool httpd_can_network_connect | grep -q "on$"').and_return(false)
  end

  platforms.each do |platform, platform_info|
    platform_info['versions'].each do |version|
      context "on #{platform} #{version}" do
        # Recipe using the httpd_install resource
        let(:test_recipe) do
          <<-EOH
            httpd_install 'default' do
              action :install
            end
          EOH
        end

        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(
            step_into: ['httpd_install'],
            platform: platform,
            version: version
          )
          runner.converge('test::httpd_install')
        end

        it 'converges successfully' do
          expect { chef_run }.to_not raise_error
        end

        context 'package installation' do
          before do
            allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).and_return(nil)
          end

          it 'installs the correct package' do
            expect(chef_run).to install_package(platform_info['package_name'])
          end

          it 'creates MPM configuration template' do
            if platform == 'centos'
              expect(chef_run).to create_template('/etc/httpd/mpm.conf')
            elsif platform == 'ubuntu'
              expect(chef_run).to create_template('/etc/apache2/mods-available/mpm_event.conf')
            end
          end
        end

        context 'selinux configuration on RHEL platforms' do
          before do
            stub_command('ls -ldZ /var/www/html | grep -q httpd_sys_content_t').and_return(false)
          end

          it 'configures selinux ports and policies on RHEL platforms' do
            expect(chef_run).to run_execute('selinux-port-80') if platform == 'centos'
          end
        end
      end
    end
  end
end
