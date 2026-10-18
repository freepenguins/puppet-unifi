# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-10-18

First release as `freepenguins-unifi`, forked from
[jmkeyes/puppet-unifi](https://github.com/jmkeyes/puppet-unifi) 0.0.4. See
"Upgrading from jmkeyes-unifi" in the README.

### Added
- Puppet 7 and 8 support; Debian 11/12 and Ubuntu 22.04/24.04.
- Installs UniFi 10.6.106 by default from Ubiquiti's download server
  (`install_from`, `package_url`, `package_checksums`, `download_dir`), with
  the download verified against its SHA-256.
- MongoDB's APT repository (8.0, or 7.0 on Debian 11) and Java 25 (Ubuntu's
  OpenJDK, or Temurin from Adoptium on Debian), installed before UniFi.
- `settings` parameter for `unifi::setting` resources, which now restart
  UniFi when they change.
- Unit tests for every supported OS.

### Changed
- Converted to PDK 3.4.0 with pdk-templates 3.8.0.
- Ubiquiti's repository is `https://dl.ui.com/unifi/debian` with its key as
  a keyring (`repo_key_name`, `repo_key_source`).
- Typed parameters, with per-OS defaults in module Hiera data.
- `unifi::setting` is titled by property name, and quotes its value.
- Dependencies: puppetlabs/stdlib 9-10, puppetlabs/apt 9.2-11,
  puppetlabs/java_ks 5-6.

### Removed
- `repo_key_id` and `repo_key_server` (apt-key and keyservers are
  deprecated), the unused `log_path` and `run_path`, the Puppet 3 version
  check, and Puppet < 7 and Debian 7-10 support.
