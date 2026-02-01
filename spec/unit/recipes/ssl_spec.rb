# frozen_string_literal: true

require 'spec_helper'

describe 'httpd::ssl' do
  context 'on Ubuntu 22.04' do
    platform 'ubuntu', '22.04'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs openssl package' do
      expect(chef_run).to install_package('openssl')
    end

    it 'defines ssl module enable execute resource' do
      expect(chef_run.execute('a2enmod ssl')).to_not be_nil
    end

    it 'creates ssl configuration directory' do
      expect(chef_run).to create_directory('/etc/apache2/ssl').with(
        owner: 'root',
        group: 'root',
        mode: '0750'
      )
    end

    it 'creates ssl hardening configuration file' do
      expect(chef_run).to create_template('/etc/apache2/conf-available/ssl-hardening.conf')
    end

    it 'creates ssl hardening execute resource' do
      resource = chef_run.execute('a2enconf ssl-hardening')
      expect(resource).to_not be_nil
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

    it 'creates ssl hardening configuration file' do
      expect(chef_run).to create_template('/etc/httpd/conf.d/ssl-hardening.conf')
    end
  end

  context 'with Let\'s Encrypt enabled' do
    platform 'ubuntu', '22.04'

    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '22.04') do |node|
        node.normal['httpd']['ssl']['letsencrypt'] = {
          'enabled' => true,
          'contact' => 'admin@example.com',
          'domains' => ['example.com'],
        }
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
