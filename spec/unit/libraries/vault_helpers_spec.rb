# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/vault_helpers'

describe Httpd::VaultHelpers do
  include Httpd::VaultHelpers

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04') do |node|
      node.default['httpd']['config']['group'] = 'www-data'
    end
  end

  before do
    test_cert_data = {
      'cert' => '-----BEGIN CERTIFICATE-----\nMIIDXTCCAkWgAwIBAgIJAJC1HiIAZAiIMA==\n-----END CERTIFICATE-----',
      'key' => '-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDHZB\n-----END PRIVATE KEY-----',
      'chain' => '-----BEGIN CERTIFICATE-----\nMIIDXTCCAkWgAwIBBBBJAJC1HiIAZAiIMA==\n-----END CERTIFICATE-----',
    }

    # Stub data_bag_item which is what the library actually calls
    allow(self).to receive(:data_bag_item).with('ssl_certificates', 'test_cert').and_return(test_cert_data)
    allow(self).to receive(:data_bag_item).with('ssl_certificates', 'missing_cert').and_raise(
      StandardError, '404 Not Found'
    )
  end

  context '#get_vault_data' do
    it 'returns the data bag item when the item exists' do
      expect(get_vault_data('ssl_certificates', 'test_cert')).to be_a(Hash)
      expect(get_vault_data('ssl_certificates', 'test_cert')['cert']).to include('BEGIN CERTIFICATE')
    end

    it 'returns a specific key value when key is provided' do
      expect(get_vault_data('ssl_certificates', 'test_cert', 'cert')).to include('BEGIN CERTIFICATE')
    end

    it 'returns the default value when the key is missing' do
      expect(get_vault_data('ssl_certificates', 'test_cert', 'missing_key', 'default')).to eq('default')
    end

    it 'returns an empty hash when the data bag item does not exist' do
      expect(get_vault_data('ssl_certificates', 'missing_cert')).to eq({})
    end

    it 'returns the default value when the data bag item does not exist and a key is requested' do
      expect(get_vault_data('ssl_certificates', 'missing_cert', 'cert', 'default')).to eq('default')
    end
  end

  context '#ssl_data_from_vault' do
    it 'returns a hash with certificate data when the certificate exists' do
      result = ssl_data_from_vault('test_cert')
      expect(result).to be_a(Hash)
      expect(result['certificate']).to include('BEGIN CERTIFICATE')
      expect(result['key']).to include('BEGIN PRIVATE KEY')
      expect(result['chain']).to include('BEGIN CERTIFICATE')
    end

    it 'returns nil when the certificate does not exist' do
      expect(ssl_data_from_vault('missing_cert')).to be_nil
    end
  end
end
