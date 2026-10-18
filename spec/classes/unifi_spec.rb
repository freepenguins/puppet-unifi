# frozen_string_literal: true

require 'spec_helper'

describe 'unifi' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:codename) { os_facts[:os]['distro']['codename'] }
      let(:ubuntu) { os_facts[:os]['name'] == 'Ubuntu' }
      let(:mongodb) { (os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '11') ? '7.0' : '8.0' }

      it { is_expected.to compile.with_all_deps }

      it 'adds Ubiquiti\'s repository with its keyring' do
        is_expected.to contain_apt__source('unifi').with(
          location: 'https://dl.ui.com/unifi/debian',
          release: 'stable',
          repos: 'ubiquiti',
          key: { 'name' => 'unifi-repo.gpg', 'source' => 'https://dl.ui.com/unifi/unifi-repo.gpg' },
        )
      end

      it 'adds MongoDB\'s repository for this release' do
        is_expected.to contain_apt__source('mongodb-org').with(
          location: "https://repo.mongodb.org/apt/#{ubuntu ? 'ubuntu' : 'debian'}",
          release: "#{codename}/mongodb-org/#{mongodb}",
          repos: ubuntu ? 'multiverse' : 'main',
          key: { 'name' => "mongodb-server-#{mongodb}.asc", 'source' => "https://pgp.mongodb.com/server-#{mongodb}.asc" },
        )
      end

      it 'takes Java 25 from the distribution on Ubuntu and from Adoptium on Debian' do
        if ubuntu
          is_expected.not_to contain_apt__source('adoptium')
          is_expected.to contain_package('openjdk-25-jre-headless').that_comes_before('Package[unifi]')
        else
          is_expected.to contain_apt__source('adoptium').with(release: codename, repos: 'main')
          is_expected.to contain_package('temurin-25-jre').that_comes_before('Package[unifi]')
        end
      end

      it 'updates APT before installing anything' do
        is_expected.to contain_class('apt::update').that_comes_before('Class[unifi::install]')
      end

      it { is_expected.to contain_package('unifi').with_ensure('installed') }
      it { is_expected.to contain_service('unifi').with(ensure: 'running', enable: true) }
      it { is_expected.to contain_class('unifi::config').that_notifies('Class[unifi::service]') }
      it { is_expected.not_to contain_java_ks('unifi:/var/lib/unifi/keystore') }

      context 'with a certificate' do
        let(:params) { { ssl_certificate: '/etc/ssl/certs/unifi.pem', ssl_private_key: '/etc/ssl/private/unifi.key' } }

        it 'imports it into UniFi\'s keystore' do
          is_expected.to contain_java_ks('unifi:/var/lib/unifi/keystore').with(
            ensure: 'latest',
            certificate: '/etc/ssl/certs/unifi.pem',
            private_key: '/etc/ssl/private/unifi.key',
            password: 'aircontrolenterprise',
          ).that_notifies('Class[unifi::service]')
        end
      end

      context 'with only half a certificate' do
        let(:params) { { ssl_certificate: '/etc/ssl/certs/unifi.pem' } }

        it { is_expected.to compile.and_raise_error(%r{set both ssl_certificate and ssl_private_key}) }
      end

      context 'without managing repositories, Java or the service' do
        let(:params) do
          { manage_repository: false, manage_mongodb_repository: false, manage_java_repository: false, java_package: :undef, manage_service: false }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_apt__source('unifi') }
        it { is_expected.not_to contain_apt__source('mongodb-org') }
        it { is_expected.not_to contain_apt__source('adoptium') }
        it { is_expected.not_to contain_service('unifi') }
        it { is_expected.to contain_package('unifi') }
      end

      context 'on a release line' do
        let(:params) { { repo_release: 'unifi-9.5', java_package: 'openjdk-21-jre-headless' } }

        it { is_expected.to contain_apt__source('unifi').with_release('unifi-9.5') }
        it { is_expected.to contain_package('openjdk-21-jre-headless').that_comes_before('Package[unifi]') }
      end

      context 'with settings' do
        let(:params) { { settings: { 'unifi.https.port' => { 'value' => 8443 } } } }

        it { is_expected.to contain_unifi__setting('unifi.https.port').with_value(8443) }
        it { is_expected.to contain_augeas('unifi-setting-unifi.https.port').with_changes("set unifi.https.port '8443'") }
      end
    end
  end

  context 'on a non-Debian system' do
    let(:facts) { { os: { 'family' => 'RedHat', 'name' => 'RedHat', 'release' => { 'major' => '9' } } } }
    let(:params) do
      { manage_java_repository: false, java_package: :undef, mongodb_repo_location: 'https://example.com', mongodb_repo_component: 'main' }
    end

    it { is_expected.to compile.and_raise_error(%r{only publishes UniFi for Debian and Ubuntu}) }
  end
end
