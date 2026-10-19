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

      it 'downloads 10.6.106, verifies it and installs it with apt' do
        is_expected.to contain_file('/var/cache/unifi').with_ensure('directory')
        is_expected.to contain_file('/var/cache/unifi/unifi_10.6.106-36011-1_all.deb').with(
          source: 'https://dl.ui.com/unifi/10.6.106/unifi_sysvinit_all.deb',
          checksum: 'sha256',
          checksum_value: 'e93b70e73b9983c5e4d0a8ccc2d5d19b86db05e78f9a8c1850caf89ac069b240',
          replace: true,
        ).that_comes_before('Package[unifi]')
        is_expected.to contain_package('unifi').with(
          ensure: '10.6.106-36011-1',
          provider: 'apt',
          source: '/var/cache/unifi/unifi_10.6.106-36011-1_all.deb',
        )
      end

      it 'doesn\'t add Ubiquiti\'s APT repository for a download' do
        is_expected.not_to contain_apt__source('unifi')
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

      context 'with a Sensitive keystore password' do
        let(:params) do
          { ssl_certificate: '/etc/ssl/certs/unifi.pem', ssl_private_key: '/etc/ssl/private/unifi.key', keystore_password: sensitive('aircontrolenterprise') }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_java_ks('unifi:/var/lib/unifi/keystore').with_password(sensitive('aircontrolenterprise')) }
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

      context 'with another version from the download server' do
        let(:params) { { package_ensure: '10.4.57-34628-1' } }

        it 'downloads that version once, without a checksum to verify' do
          is_expected.to contain_file('/var/cache/unifi/unifi_10.4.57-34628-1_all.deb').with(
            source: 'https://dl.ui.com/unifi/10.4.57/unifi_sysvinit_all.deb', checksum: nil, checksum_value: nil, replace: false,
          )
          is_expected.to contain_package('unifi').with_ensure('10.4.57-34628-1')
        end
      end

      context 'downloading without a full package version' do
        let(:params) { { package_ensure: 'latest' } }

        it { is_expected.to compile.and_raise_error(%r{set package_ensure to a full package version}) }
      end

      context 'from Ubiquiti\'s APT repository' do
        let(:params) { { install_from: 'repository', repo_release: 'unifi-10.4', package_ensure: 'latest' } }

        it 'adds the repository with its keyring' do
          is_expected.to contain_apt__source('unifi').with(
            location: 'https://dl.ui.com/unifi/debian',
            release: 'unifi-10.4',
            repos: 'ubiquiti',
            key: { 'name' => 'unifi-repo.gpg', 'source' => 'https://dl.ui.com/unifi/unifi-repo.gpg' },
          )
        end

        it { is_expected.to contain_package('unifi').with(ensure: 'latest', provider: nil, source: nil) }
        it { is_expected.not_to contain_file('/var/cache/unifi') }
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
