# frozen_string_literal: true

require 'spec_helper'

describe 'httpd::ssl' do
  context 'on Ubuntu 22.04' do
    platform 'ubuntu', '22.04'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs mod_ssl package' do
      expect(chef_run).to install_package('openssl')
    end

    it 'enables ssl module' do
      expect(chef_run).to run_execute('a2enmod ssl')
    end

    it 'creates ssl configuration directory' do
      expect(chef_run).to create_directory('/etc/apache2/ssl').with(
        owner: 'root',
        group: 'root',
        mode: '0750'
      )
    end

    it 'creates ssl configuration file' do
      expect(chef_run).to create_template('/etc/apache2/conf-available/ssl-hardening.conf')
    end

    it 'enables ssl hardening configuration' do
      expect(chef_run).to run_execute('a2enconf ssl-hardening')
    end
  end

  context 'on Rocky Linux 9' do
    platform 'rocky', '9'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs mod_ssl package' do
      expect(chef_run).to install_package('mod_ssl')
    end

    it 'creates ssl configuration file' do
      expect(chef_run).to create_template('/etc/httpd/conf.d/ssl-hardening.conf')
    end
  end

  context 'with Let\'s Encrypt enabled' do
    platform 'ubuntu', '22.04'

    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.normal['httpd']['ssl']['letsencrypt']['enabled'] = true
        node.normal['httpd']['ssl']['letsencrypt']['contact'] = 'admin@example.com'
        node.normal['httpd']['ssl']['letsencrypt']['domains'] = ['example.com']
      end.converge(described_recipe)
    end

    it 'installs certbot package' do
      expect(chef_run).to install_package('certbot')
    end

    it 'installs python3-certbot-apache package' do
      expect(chef_run).to install_package('python3-certbot-apache')
    end

    it 'creates certbot renewal cron job' do
      expect(chef_run).to create_cron('certbot-renewal').with(
        command: '/usr/bin/certbot renew --quiet --deploy-hook "systemctl reload apache2"',
        hour: '3',
        minute: '30'
      )
    end
  end
end
