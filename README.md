# unifi

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with unifi](#setup)
    * [What unifi affects](#what-unifi-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with unifi](#beginning-with-unifi)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Upgrading from jmkeyes-unifi](#upgrading-from-jmkeyes-unifi)
1. [Development - Guide for contributing to the module](#development)

## Description

This module installs the [UniFi Network application](https://ui.com) (the
UniFi controller) on Debian and Ubuntu, together with the MongoDB and Java it
needs, and can give its web interface your own TLS certificate and set
properties in its `system.properties`.

It is a fork of [jmkeyes/puppet-unifi](https://github.com/jmkeyes/puppet-unifi)
(`jmkeyes-unifi` on the Forge), updated for Puppet 7 and 8, current UniFi
releases and the PDK. See [Upgrading](#upgrading-from-jmkeyes-unifi) for
what changed.

## Setup

### What unifi affects

* The `unifi` package, version 10.6.106 by default, downloaded from Ubiquiti
  to `/var/cache/unifi/` and installed with APT so its dependencies come from
  APT too. Or, with `install_from => 'repository'`, Ubiquiti's APT repository
  (`https://dl.ui.com/unifi/debian`, key in
  `/etc/apt/keyrings/unifi-repo.gpg`).
* MongoDB's APT repository (`manage_mongodb_repository`): MongoDB 8.0, or
  7.0 on Debian 11, the newest MongoDB publishes there. UniFi accepts 3.6 up
  to, not including, 8.1.
* Java 25, installed before UniFi (`java_package`): Ubuntu's own
  `openjdk-25-jre-headless`, or on Debian `temurin-25-jre` from Adoptium's
  repository (`manage_java_repository`).
* The `unifi` service.
* With `ssl_certificate` and `ssl_private_key`: the `unifi` entry in
  `/var/lib/unifi/keystore`.
* With `settings` or `unifi::setting`: properties in
  `/var/lib/unifi/system.properties`.
* `/etc/logrotate.d/unifi` (`manage_logrotate`), which rotates the MongoDB
  log UniFi runs; by default the same rules as the package's file.
* With `manage_defaults`: `/etc/default/unifi`, the environment for the
  service and the package's scripts.

### Setup requirements

* Puppet 7 or 8, with puppetlabs/stdlib 9 or later, puppetlabs/apt 9.2 or
  later and puppetlabs/java_ks. `unifi::setting` uses Augeas, which Puppet's
  agent packages include.
* A 64-bit (amd64 or arm64) Debian 11 or 12, or Ubuntu 22.04 or 24.04.
* MongoDB 5.0 and later need a CPU with AVX on amd64. On a VM, make sure AVX
  is passed through to the guest.

### Beginning with unifi

```puppet
include unifi
```

That installs UniFi 10.6.106 with MongoDB and Java and starts it. The web
interface is on `https://<host>:8443/`.

## Usage

### Choosing the version

Ubiquiti publishes UniFi as a .deb at
`https://dl.ui.com/unifi/<version>/unifi_sysvinit_all.deb`, sometimes before
(or without) adding it to its APT repository. By default the module installs
the version in `package_ensure` from there. Use the full Debian version, with
the build number, which `dpkg-deb -f unifi_sysvinit_all.deb Version` shows:

```yaml
unifi::package_ensure: '10.6.106-36011-1'
```

The module checks the download against `package_checksums` when it knows the
version (10.6.106 is included). For another version, add its SHA-256:

```yaml
unifi::package_ensure: '10.4.57-34628-1'
unifi::package_checksums:
  '10.4.57-34628-1': 'fc378cf8cd2bec3d334bf7b72eabfcd1861e5fae67b9c16735471132105b2072'
```

To follow Ubiquiti's APT repository instead, pick a suite. `stable` follows
the newest release, and `unifi-10.4` and so on stay on one release line:

```yaml
unifi::install_from: repository
unifi::repo_release: 'unifi-10.4'
unifi::package_ensure: latest
```

At the time of writing, `stable` and `unifi-10.6` have no package in them,
so a repository install of 10.6 isn't possible yet.

### Java and MongoDB

UniFi 10.x needs Java 25; 9.x accepted 17 or 21. The module installs
`java_package` before UniFi so that APT doesn't satisfy the dependency with a
full JDK. For a 9.x release line, set it to a Java 17 or 21 package:

```yaml
unifi::java_package: 'openjdk-21-jre-headless'
```

If you manage Java or MongoDB some other way, turn the module's handling off:

```yaml
unifi::manage_java_repository: false
unifi::java_package: ~
unifi::manage_mongodb_repository: false
```

### TLS certificate

```puppet
class { 'unifi':
  ssl_certificate => '/etc/ssl/certs/unifi.example.com.pem',
  ssl_private_key => '/etc/ssl/private/unifi.example.com.key',
}
```

The certificate (with its chain) and key are PEM files on the host, for
example from Let's Encrypt. `keystore_password` can be `Sensitive`. They're imported into the `unifi` entry of
UniFi's keystore, and UniFi restarts when they change.

### system.properties

```yaml
unifi::settings:
  unifi.http.port:
    value: 8081
  unifi.https.port:
    value: 8443
```

or

```puppet
unifi::setting { 'unifi.http.port':
  value => 8081,
}
```

Each change restarts UniFi, which reads the file when it starts. The
`settings` hash is declared in `unifi::config`, and the restart relies on
that class's `~>` to `unifi::service`; a `unifi::setting` declared elsewhere
notifies the service itself.

### Java heap and other environment variables

UniFi's service and the package's scripts read `/etc/default/unifi`. With
`manage_defaults` the module writes it from `defaults` and restarts UniFi
when it changes. Heap sizes are in MB:

```yaml
unifi::manage_defaults: true
unifi::defaults:
  JVM_INIT_HEAP_SIZE: 1024
  JVM_MAX_HEAP_SIZE: 4096
  UNIFI_JVM_EXTRA_OPTS: '-Dlog4j2.formatMsgNoLookups=true'
```

Values are double-quoted with `\`, `"`, `$` and `` ` `` escaped, so systemd
and the shell both read them literally. The package's unit then passes
`$UNIFI_JVM_OPTS` to Java split at whitespace, so a single JVM option can't
contain a space: `-Dfoo=a b` becomes two arguments, whatever the quoting. `unifi.xms` and `unifi.xmx` in
`system.properties`, if set, take precedence over the heap variables.

### Log rotation

The module manages `/etc/logrotate.d/unifi`, which rotates UniFi's MongoDB
log (`/usr/lib/unifi/logs/mongod.log`). The defaults match the package's own
file: 5 rotations of 50M, compressed. UniFi rotates its own `server.log`.

```yaml
unifi::logrotate_rotate: 14
unifi::logrotate_size: '200M'
```

Set `unifi::manage_logrotate: false` to leave the package's file alone.

## Reference

See [REFERENCE.md](REFERENCE.md), and `examples/` for a manifest per use
case: the default install, another version, the APT repository, a TLS
certificate, settings, Java heap, log rotation, and bringing your own MongoDB
and Java.

## Limitations

* Debian 11 and 12, Ubuntu 22.04 and 24.04, amd64 or arm64. Debian 13 is
  not supported yet: MongoDB has no 8.0 server package for it, and UniFi
  doesn't accept 8.1 or later.
* One UniFi per host.
* The keystore password is UniFi's default, `aircontrolenterprise`, which is
  what UniFi opens it with.
* The module doesn't back up UniFi's data or migrate MongoDB between major
  versions. Back up from the UniFi interface before upgrading either.

## Upgrading from jmkeyes-unifi

The class keeps its name and most parameters. What changed:

* **Default install:** UniFi 10.6.106 from Ubiquiti's download server rather
  than whatever `stable` held. Set `install_from => 'repository'` for the old
  behaviour.
* **Repository:** `https://dl.ui.com/unifi/debian` with its key from
  `https://dl.ui.com/unifi/unifi-repo.gpg` as a keyring, instead of
  `apt::key` from a keyserver. `repo_key_id` and `repo_key_server` are gone;
  use `repo_key_name` and `repo_key_source`.
* **Dependencies:** UniFi now needs MongoDB and Java 25, which the old module
  left to you. The module adds MongoDB's repository and installs Java first.
* **Settings:** `unifi::setting` resources are titled by property name and
  restart UniFi. The `settings` parameter declares them from Hiera.
* **Removed:** `log_path` and `run_path` (unused), the Puppet 3 version check,
  and support for Puppet before 7 and for Debian 7–10.

## Development

This is a PDK module (pdk-templates 3.8.0). Run the checks with:

```
pdk validate
pdk test unit
```

The unit tests cover every supported OS on the Puppet version you run them
with; run them with `PUPPET_GEM_VERSION='~> 7'` and `'~> 8'` to cover both.

Original module by Joshua Keyes, with a contribution from slyoldfox.
Licensed under Apache 2.0.
