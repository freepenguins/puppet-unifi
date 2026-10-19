# Another UniFi version from Ubiquiti's download server, verified against its
# SHA-256 (from the .deb's SHA256 in Ubiquiti's Packages file, or sha256sum).
class { 'unifi':
  package_ensure    => '10.4.57-34628-1',
  package_checksums => {
    '10.4.57-34628-1' => 'fc378cf8cd2bec3d334bf7b72eabfcd1861e5fae67b9c16735471132105b2072',
  },
}
