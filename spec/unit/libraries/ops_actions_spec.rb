# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/ops_actions'

describe Httpd::OpsActions do
  let(:node_data) do
    {
      'hostname' => 'testhost',
      'platform' => 'ubuntu',
      'platform_version' => '20.04',
      'platform_family' => 'debian',
    }
  end

  let(:subject) { Object.new.extend(Httpd::OpsActions) }

  let(:shell_out_success) { double('shellout', exitstatus: 0, stdout: 'Server version: Apache/2.4.41 (Ubuntu)', stderr: '') }
  let(:shell_out_failure) { double('shellout', exitstatus: 1, stdout: '', stderr: 'Error') }

  before do
    allow(subject).to receive(:node).and_return(double('node', :[] => nil).tap { |n|
      allow(n).to receive(:[]).with('platform_family').and_return('debian')
      allow(n).to receive(:[]).with('hostname').and_return('testhost')
      allow(n).to receive(:[]).with('platform').and_return('ubuntu')
      allow(n).to receive(:[]).with('platform_version').and_return('20.04')
    })
    allow(subject).to receive(:shell_out).and_return(shell_out_success)
    allow(subject).to receive(:httpd_service_name).and_return('apache2')
    allow(subject).to receive(:platform_family?).and_return(false)
    allow(subject).to receive(:platform_family?).with('debian').and_return(true)
    allow(subject).to receive(:file).and_return(nil)
    allow(subject).to receive(:service).and_return(nil)
  end

  describe '#apache_version' do
    it 'parses Apache version from command output' do
      allow(subject).to receive(:platform_family?).with('debian').and_return(true)
      allow(subject).to receive(:shell_out).with('apache2 -v').and_return(
        double('shellout', exitstatus: 0, stdout: 'Server version: Apache/2.4.41 (Ubuntu)')
      )

      expect(subject.apache_version).to eq('2.4.41')
    end

    it 'returns unknown if command fails' do
      allow(subject).to receive(:platform_family?).with('debian').and_return(true)
      allow(subject).to receive(:shell_out).with('apache2 -v').and_return(
        double('shellout', exitstatus: 1, stdout: '')
      )

      expect(subject.apache_version).to eq('unknown')
    end

    it 'returns unknown if version cannot be parsed' do
      allow(subject).to receive(:platform_family?).with('debian').and_return(true)
      allow(subject).to receive(:shell_out).with('apache2 -v').and_return(
        double('shellout', exitstatus: 0, stdout: 'Invalid output')
      )

      expect(subject.apache_version).to eq('unknown')
    end
  end

  describe '#backup_config' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with('/var/backups/httpd').and_return(false)
      allow(FileUtils).to receive(:mkdir_p)
      allow(Time).to receive(:now).and_return(Time.new(2025, 5, 16, 12, 0, 0))
    end

    it 'creates a backup directory if it does not exist' do
      expect(FileUtils).to receive(:mkdir_p).with('/var/backups/httpd')
      subject.backup_config
    end

    it 'returns the path to the backup file on success' do
      result = subject.backup_config
      expect(result).to eq('/var/backups/httpd/apache-config-20250516-120000.tar.gz')
    end

    it 'returns nil if creating the archive fails' do
      allow(subject).to receive(:shell_out).and_return(shell_out_failure)
      expect(Chef::Log).to receive(:error).with(/Failed to create backup archive/)
      expect(subject.backup_config).to be_nil
    end
  end

  describe '#restore_config' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:cp_r)
      allow(FileUtils).to receive(:chmod_R)
      allow(FileUtils).to receive(:rm_rf)
      allow(FileUtils).to receive(:remove_entry)
      allow(Dir).to receive(:mktmpdir).and_return('/tmp/apache-restore')
      allow(Time).to receive(:now).and_return(Time.new(2025, 5, 16, 12, 0, 0))
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with('/var/backups/httpd').and_return(true)
    end

    it 'returns false if backup file does not exist' do
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with('/nonexistent.tar.gz').and_return(false)
      expect(subject.restore_config('/nonexistent.tar.gz')).to be false
    end
  end
end
