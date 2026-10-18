# @summary Adds the APT repositories UniFi and its dependencies come from.
#
# @api private
class unifi::repo {
  assert_private()

  # Strings rather than arrays: puppetlabs-apt accepts arrays only from
  # 10.0.0. With only `name` and `source` in the key hash, apt writes a
  # keyring and signed-by instead of using the deprecated apt-key.
  if $unifi::manage_repository {
    apt::source { 'unifi':
      comment       => 'Ubiquiti UniFi Network application',
      location      => $unifi::repo_location,
      release       => $unifi::repo_release,
      repos         => 'ubiquiti',
      key           => {
        'name'   => $unifi::repo_key_name,
        'source' => $unifi::repo_key_source,
      },
      notify_update => true,
    }
  }

  if $unifi::manage_mongodb_repository {
    $mongodb_version = $unifi::mongodb_version
    apt::source { 'mongodb-org':
      comment       => "MongoDB ${mongodb_version}, for UniFi",
      location      => $unifi::mongodb_repo_location,
      release       => "${facts['os']['distro']['codename']}/mongodb-org/${mongodb_version}",
      repos         => $unifi::mongodb_repo_component,
      key           => {
        'name'   => "mongodb-server-${mongodb_version}.asc",
        'source' => "https://pgp.mongodb.com/server-${mongodb_version}.asc",
      },
      notify_update => true,
    }
  }

  if $unifi::manage_java_repository {
    apt::source { 'adoptium':
      comment       => 'Adoptium Temurin Java, for UniFi',
      location      => $unifi::java_repo_location,
      release       => $facts['os']['distro']['codename'],
      repos         => 'main',
      key           => {
        'name'   => 'adoptium.asc',
        'source' => 'https://packages.adoptium.net/artifactory/api/gpg/key/public',
      },
      notify_update => true,
    }
  }

  # Every source above must be in APT's index before anything is installed.
  if $unifi::manage_repository or $unifi::manage_mongodb_repository or $unifi::manage_java_repository {
    Class['apt::update'] -> Class['unifi::install']
  }
}
