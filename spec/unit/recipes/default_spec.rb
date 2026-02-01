# frozen_string_literal: true

require 'spec_helper'

describe 'httpd::default' do
  context 'on Ubuntu 22.04' do
    platform 'ubuntu', '22.04'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'includes the install recipe' do
      expect(chef_run).to include_recipe('httpd::install')
    end

    it 'includes the configure recipe' do
      expect(chef_run).to include_recipe('httpd::configure')
    end

    it 'includes the vhosts recipe' do
      expect(chef_run).to include_recipe('httpd::vhosts')
    end

    it 'includes the service recipe' do
      expect(chef_run).to include_recipe('httpd::service')
    end
  end

  context 'on Rocky Linux 9' do
    platform 'rocky', '9'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'includes the install recipe' do
      expect(chef_run).to include_recipe('httpd::install')
    end
  end

  context 'on Amazon Linux 2023' do
    platform 'amazon', '2023'

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end

    it 'includes the install recipe' do
      expect(chef_run).to include_recipe('httpd::install')
    end
  end
end
