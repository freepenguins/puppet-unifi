# @summary Installs Java, then UniFi (which pulls in MongoDB).
#
# @api private
class unifi::install {
  assert_private()

  # Installed first, so that APT doesn't satisfy the `unifi` package's Java
  # dependency with the first alternative it lists, which can be a full JDK.
  if $unifi::java_package {
    package { $unifi::java_package:
      ensure => installed,
    }
    $java = Package[$unifi::java_package]
  } else {
    $java = undef
  }

  if $unifi::manage_package {
    if $unifi::install_from == 'download' {
      # 10.6.106-36011-1 is published as https://dl.ui.com/unifi/10.6.106/...
      $upstream = $unifi::package_ensure.split('-')[0]
      $url = pick($unifi::package_url, "https://dl.ui.com/unifi/${upstream}/unifi_sysvinit_all.deb")
      $deb = "${unifi::download_dir}/unifi_${unifi::package_ensure}_all.deb"
      $checksum = $unifi::package_checksums[$unifi::package_ensure]
      $checksum_type = $checksum ? {
        undef   => undef,
        default => 'sha256',
      }

      file { $unifi::download_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }

      # Named by version, so it's downloaded once per version. Without a
      # known checksum it isn't fetched again once it exists.
      file { $deb:
        ensure         => file,
        source         => $url,
        checksum       => $checksum_type,
        checksum_value => $checksum,
        replace        => $checksum != undef,
        owner          => 'root',
        group          => 'root',
        mode           => '0644',
        before         => Package[$unifi::package_name],
      }

      # The apt provider installs a local .deb with `apt-get install`, so
      # MongoDB and the other dependencies still come from APT.
      package { $unifi::package_name:
        ensure   => $unifi::package_ensure,
        provider => 'apt',
        source   => $deb,
        require  => $java,
      }
    } else {
      package { $unifi::package_name:
        ensure  => $unifi::package_ensure,
        require => $java,
      }
    }
  }
}
