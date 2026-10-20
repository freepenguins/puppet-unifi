# frozen_string_literal: true

require 'spec_helper'

describe 'unifi::setting' do
  let(:pre_condition) { 'include unifi' }
  let(:facts) { on_supported_os['debian-12-x86_64'] }
  let(:title) { 'unifi.http.port' }

  context 'setting a value' do
    let(:params) { { value: 8081 } }

    it { is_expected.to compile.with_all_deps }

    it 'edits system.properties and restarts UniFi' do
      is_expected.to contain_augeas('unifi-setting-unifi.http.port').with(
        incl: '/var/lib/unifi/system.properties',
        lens: 'Properties.lns',
        changes: "set unifi.http.port '8081'",
      ).that_requires('Class[unifi::install]').that_notifies('Class[unifi::service]')
    end
  end

  context 'with a quote in the value' do
    let(:params) { { value: "it's" } }

    it { is_expected.to contain_augeas('unifi-setting-unifi.http.port').with_changes("set unifi.http.port 'it\\'s'") }
  end

  context 'removing a property' do
    let(:params) { { ensure: 'absent' } }

    it { is_expected.to contain_augeas('unifi-setting-unifi.http.port').with_changes('rm unifi.http.port') }
  end

  context 'with the property set apart from the title' do
    let(:title) { 'inform port' }
    let(:params) { { property: 'unifi.http.port', value: 8081 } }

    it { is_expected.to contain_augeas('unifi-setting-unifi.http.port').with_changes("set unifi.http.port '8081'") }
  end

  ['unifi http.port', 'unifi/http.port', "unifi.http.port'x"].each do |bad|
    context "with the property name #{bad.inspect}" do
      let(:title) { bad }
      let(:params) { { value: 1 } }

      it { is_expected.to compile.and_raise_error(%r{property}) }
    end
  end

  context 'without a value' do
    it { is_expected.to compile.and_raise_error(%r{set a value, or ensure => absent}) }
  end
end
