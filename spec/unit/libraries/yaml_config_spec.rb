# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/yaml_config'

describe Httpd::YAMLConfig do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '20.04')
  end

  let(:subject) { Object.new.extend(Httpd::YAMLConfig) }

  let(:run_context) do
    node = Chef::Node.new
    Chef::RunContext.new(node, {}, nil)
  end

  before do
    allow(subject).to receive(:file) do |path, &block|
      # Mock file resource - use instance_eval since Chef DSL blocks are evaluated on the resource
      resource = Chef::Resource::File.new(path, run_context)
      resource.instance_eval(&block) if block
      resource
    end

    # Stub Chef.logger for methods that use it
    logger = double('logger')
    allow(logger).to receive(:warn)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(Chef).to receive(:logger).and_return(logger)
  end

  describe '#create_yaml_config' do
    it 'creates a file with YAML content' do
      resource = subject.create_yaml_config('/etc/httpd/conf.d/config.yaml', { key: 'value' })

      expect(resource).to be_a(Chef::Resource::File)
      expect(resource.path).to eq('/etc/httpd/conf.d/config.yaml')
      expect(resource.content).to eq(YAML.dump({ key: 'value' }))
      expect(resource.owner).to eq('root')
      expect(resource.group).to eq('root')
      expect(resource.mode).to eq('0644')
      expect(resource.action).to eq([:create])
    end

    it 'respects custom owner, group, and mode' do
      resource = subject.create_yaml_config('/etc/httpd/conf.d/config.yaml',
                                            { key: 'value' },
                                            owner: 'apache',
                                            group: 'apache',
                                            mode: '0640')

      expect(resource.owner).to eq('apache')
      expect(resource.group).to eq('apache')
      expect(resource.mode).to eq('0640')
    end
  end

  describe '#read_yaml_config' do
    it 'reads and parses an existing YAML file' do
      allow(::File).to receive(:exist?).with('/etc/httpd/conf.d/config.yaml').and_return(true)
      allow(YAML).to receive(:load_file).with('/etc/httpd/conf.d/config.yaml', permitted_classes: [Symbol]).and_return({ 'key' => 'value' })

      result = subject.read_yaml_config('/etc/httpd/conf.d/config.yaml')

      expect(result).to eq({ 'key' => 'value' })
    end

    it 'returns an empty hash when file does not exist' do
      allow(::File).to receive(:exist?).with('/etc/httpd/conf.d/missing.yaml').and_return(false)

      result = subject.read_yaml_config('/etc/httpd/conf.d/missing.yaml')

      expect(result).to eq({})
    end

    it 'returns an empty hash on parsing error' do
      allow(::File).to receive(:exist?).with('/etc/httpd/conf.d/invalid.yaml').and_return(true)
      allow(YAML).to receive(:load_file).with('/etc/httpd/conf.d/invalid.yaml', permitted_classes: [Symbol]).and_raise(Psych::SyntaxError.new(
                                                                                            'file', 1, 1, 0, 'error', 'problem'
                                                                                          ))

      result = subject.read_yaml_config('/etc/httpd/conf.d/invalid.yaml')

      expect(result).to eq({})
    end
  end

  describe '#merge_yaml_config' do
    it 'merges new configuration with existing configuration' do
      allow(subject).to receive(:read_yaml_config).with('/etc/httpd/conf.d/config.yaml').and_return({
                                                                                                      'existing' => 'value', 'nested' => { 'key' => 'value' }
                                                                                                    })

      resource = subject.merge_yaml_config('/etc/httpd/conf.d/config.yaml',
                                           { 'new' => 'value', 'nested' => { 'new_key' => 'new_value' } })

      expect(resource).to be_a(Chef::Resource::File)
      expect(resource.content).to include('existing: value')
      expect(resource.content).to include('new: value')
      expect(resource.content).to include('key: value')
      expect(resource.content).to include('new_key: new_value')
    end
  end

  describe '#hash_to_yaml' do
    it 'converts a hash to YAML string' do
      result = subject.hash_to_yaml({ 'key' => 'value', 'nested' => { 'key' => 'value' } })

      expect(result).to include('key: value')
      expect(result).to include('nested:')
      expect(result).to include('  key: value')
    end

    it 'handles errors gracefully' do
      # Stub YAML.dump to raise an error
      allow(YAML).to receive(:dump).and_raise(StandardError, 'Test error')

      result = subject.hash_to_yaml({ 'key' => 'value' })

      expect(result).to eq("{}\n")
    end
  end

  describe '#yaml_to_hash' do
    it 'parses a YAML string to a hash' do
      yaml_string = "---\nkey: value\nnested:\n  key: value\n"

      result = subject.yaml_to_hash(yaml_string)

      expect(result).to eq({ 'key' => 'value', 'nested' => { 'key' => 'value' } })
    end

    it 'handles parsing errors gracefully' do
      allow(YAML).to receive(:safe_load).and_raise(Psych::SyntaxError.new('file', 1, 1, 0, 'error', 'problem'))

      result = subject.yaml_to_hash('invalid')

      expect(result).to eq({})
    end
  end
end
