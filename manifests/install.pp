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
  }

  if $unifi::manage_package {
    package { $unifi::package_name:
      ensure  => $unifi::package_ensure,
      require => $unifi::java_package ? {
        undef   => undef,
        default => Package[$unifi::java_package],
      },
    }
  }
}
