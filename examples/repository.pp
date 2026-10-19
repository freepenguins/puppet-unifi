# Follow a release line in Ubiquiti's APT repository instead of a pinned
# download. `stable` follows the newest release; `unifi-10.4` stays on 10.4.
class { 'unifi':
  install_from   => 'repository',
  repo_release   => 'unifi-10.4',
  package_ensure => 'latest',
}
