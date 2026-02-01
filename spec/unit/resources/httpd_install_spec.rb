# frozen_string_literal: true

require 'spec_helper'

describe 'test::httpd_install' do
  platforms = {
    'ubuntu' => {
      'versions' => ['20.04'],
      'package_name' => 'apache2',
      'service_name' => 'apache2',
      'conf_dir' => '/etc/apache2',
    },
    'centos' => {
      'versions' => %w(8),
      'package_name' => 'httpd',
      'service_name' => 'httpd',
      'conf_dir' => '/etc/httpd/conf',
    },
  }

  before do
    stub_command('getenforce | grep -i disabled').and_return(false)
    stub_command('sestatus | grep -q "SELinux status: enabled"').and_return(true)
    stub_command('semanage port -l | grep -w \'http_port_t\' | grep -w 80').and_return(false)
    stub_command('semanage port -l | grep -w \'http_port_t\' | grep -w 443').and_return(false)
    stub_command('getsebool httpd_can_network_connect_http | grep -q "on$"').and_return(false)
    stub_command('getsebool httpd_can_network_connect | grep -q "on$"').and_return(false)
    stub_command('ls -ldZ /var/www/html | grep -q httpd_sys_content_t').and_return(false)
  end

  platforms.each do |platform, platform_info|
    platform_info['versions'].each do |version|
      context "on #{platform} #{version}" do
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
          it 'installs the correct package' do
            expect(chef_run).to install_package(platform_info['package_name'])
          end

          it 'creates MPM configuration' do
            expect(chef_run).to create_template("#{platform_info['conf_dir']}/mpm.conf")
          end
        end

        context 'selinux configuration on RHEL platforms' do
          it 'configures selinux ports and policies on RHEL platforms' do
            if platform == 'centos'
              expect(chef_run).to run_execute('selinux-port-80')
            end
          end
        end
      end
    end
  end

  context 'source installation on ubuntu 20.04' do
    before do
      stub_command('getenforce | grep -i disabled').and_return(false)
      stub_command('sestatus | grep -q "SELinux status: enabled"').and_return(false)
    end

    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(
        step_into: ['httpd_install'],
        platform: 'ubuntu',
        version: '20.04'
      )
      runner.node.override['httpd']['install_method'] = 'source'
      runner.node.override['httpd']['version'] = '2.4.57'
      runner.converge('test::httpd_install')
    end

    it 'installs required dependencies' do
      expect(chef_run).to install_package('httpd-deps')
    end

    it 'downloads the source tarball' do
      expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/httpd/httpd-2.4.57.tar.gz")
    end

    it 'extracts and compiles Apache' do
      expect(chef_run).to run_bash('compile-httpd')
    end
  end
end
