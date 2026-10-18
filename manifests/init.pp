# @summary Installs the UniFi Network application from Ubiquiti's APT repository.
#
# The `unifi` package depends on MongoDB (3.6 up to, not including, 8.1) and
# a Java runtime (Java 25 for UniFi 10.4, Java 17 or 21 for 9.x). Neither is
# in every distribution's own archive, so the module can add MongoDB's
# repository and, where the distribution has no suitable Java, Adoptium's
# Temurin repository, and install the Java package first so APT doesn't
# pick a full JDK to satisfy the dependency.
#
# The defaults for each OS are in the module's Hiera data.
#
# @example Install UniFi with everything it needs
#   include unifi
#
# @example Use a TLS certificate for the web interface
#   class { 'unifi':
#     ssl_certificate => '/etc/ssl/certs/unifi.example.com.pem',
#     ssl_private_key => '/etc/ssl/private/unifi.example.com.key',
#   }
#
# @example Stay on a release line
#   class { 'unifi':
#     repo_release => 'unifi-9.5',
#     java_package => 'openjdk-21-jre-headless',
#   }
#
# @param manage_repository
#   Whether to add Ubiquiti's APT repository.
# @param repo_location
#   Ubiquiti's repository URL.
# @param repo_release
#   The suite to install from: `stable` follows the newest release;
#   `unifi-10.4`, `unifi-9.5` and so on stay on one release line.
# @param repo_key_name
#   File name of Ubiquiti's signing key in `/etc/apt/keyrings`.
# @param repo_key_source
#   URL of Ubiquiti's signing key.
# @param manage_mongodb_repository
#   Whether to add MongoDB's APT repository for `mongodb_version`.
# @param mongodb_version
#   The MongoDB release series to add, such as `8.0`. UniFi needs at least
#   3.6 and less than 8.1.
# @param mongodb_repo_location
#   MongoDB's repository URL for this distribution.
# @param mongodb_repo_component
#   The repository component: `main` on Debian, `multiverse` on Ubuntu.
# @param manage_java_repository
#   Whether to add Adoptium's Temurin repository, for distributions whose own
#   archive has no Java that UniFi accepts.
# @param java_repo_location
#   Adoptium's repository URL.
# @param java_package
#   The Java runtime to install before UniFi, or undef to let APT choose from
#   the `unifi` package's dependencies.
# @param manage_package
#   Whether to install the `unifi` package.
# @param package_name
#   The UniFi package.
# @param package_ensure
#   The package's `ensure`, such as `installed`, `latest` or a version.
# @param manage_service
#   Whether to manage the UniFi service.
# @param service_name
#   The UniFi service.
# @param service_ensure
#   The service's `ensure`.
# @param service_enable
#   Whether the service starts at boot.
# @param ssl_certificate
#   Path of a PEM certificate (with its chain) for the web interface. Both
#   this and `ssl_private_key` must be set to manage the keystore.
# @param ssl_private_key
#   Path of the certificate's PEM private key.
# @param keystore_password
#   UniFi's keystore password. UniFi only opens its keystore with the default,
#   `aircontrolenterprise`.
# @param data_path
#   UniFi's data directory, where `system.properties` and the keystore live.
# @param settings
#   `unifi::setting` resources to declare, keyed by property name, such as
#   `{ 'unifi.https.port' => { 'value' => '8443' } }`.
class unifi (
  # Defaults for these are in the module's Hiera data, per OS.
  Boolean                         $manage_java_repository,
  String[1]                       $mongodb_repo_location,
  String[1]                       $mongodb_repo_component,
  String[1]                       $mongodb_version,
  Optional[String[1]]             $java_package,
  Boolean                         $manage_repository         = true,
  Stdlib::HTTPUrl                 $repo_location             = 'https://dl.ui.com/unifi/debian',
  String[1]                       $repo_release              = 'stable',
  String[1]                       $repo_key_name             = 'unifi-repo.gpg',
  Stdlib::HTTPUrl                 $repo_key_source           = 'https://dl.ui.com/unifi/unifi-repo.gpg',
  Boolean                         $manage_mongodb_repository = true,
  Stdlib::HTTPUrl                 $java_repo_location        = 'https://packages.adoptium.net/artifactory/deb',
  Boolean                         $manage_package            = true,
  String[1]                       $package_name              = 'unifi',
  String[1]                       $package_ensure            = 'installed',
  Boolean                         $manage_service            = true,
  String[1]                       $service_name              = 'unifi',
  Stdlib::Ensure::Service         $service_ensure            = 'running',
  Boolean                         $service_enable            = true,
  Optional[Stdlib::Absolutepath]  $ssl_certificate           = undef,
  Optional[Stdlib::Absolutepath]  $ssl_private_key           = undef,
  String[1]                       $keystore_password         = 'aircontrolenterprise',
  Stdlib::Absolutepath            $data_path                 = '/var/lib/unifi',
  Hash[String[1], Hash]           $settings                  = {},
) {
  unless $facts['os']['family'] == 'Debian' {
    fail("unifi: Ubiquiti only publishes UniFi for Debian and Ubuntu, not ${facts['os']['name']}.")
  }

  contain unifi::repo
  contain unifi::install
  contain unifi::config
  contain unifi::service

  Class['unifi::repo']
  -> Class['unifi::install']
  -> Class['unifi::config']
  ~> Class['unifi::service']

  $settings.each |String[1] $name, Hash $params| {
    unifi::setting { $name:
      * => $params,
    }
  }
}
