# frozen_string_literal: true

require 'spec_helper'

describe 'httpd::default' do
  context 'on Ubuntu 22.04' do
    platform 'ubuntu', '22.04'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs apache2 package' do
      expect(chef_run).to install_package('apache2')
    end

    it 'enables and starts apache2 service' do
      expect(chef_run).to enable_service('apache2')
      expect(chef_run).to start_service('apache2')
    end

    it 'creates apache configuration directory' do
      expect(chef_run).to create_directory('/etc/apache2/conf-available')
    end
  end

  context 'on Rocky Linux 9' do
    platform 'rocky', '9'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs httpd package' do
      expect(chef_run).to install_package('httpd')
    end

    it 'enables and starts httpd service' do
      expect(chef_run).to enable_service('httpd')
      expect(chef_run).to start_service('httpd')
    end
  end

  context 'on Amazon Linux 2023' do
    platform 'amazon', '2023'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'installs httpd package' do
      expect(chef_run).to install_package('httpd')
    end
  end
end
