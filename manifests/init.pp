# @summary Installs the UniFi Network application, with MongoDB and Java.
#
# By default the `unifi` package is downloaded from Ubiquiti's download
# server for the version in `package_ensure` (`install_from => 'download'`),
# because Ubiquiti publishes some releases there before, or instead of, its
# APT repository. With `install_from => 'repository'` it comes from the APT
# repository's `repo_release` suite instead.
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
# @example Install the default version (10.6.106) with everything it needs
#   include unifi
#
# @example Install another version from the download server
#   class { 'unifi':
#     package_ensure => '10.4.57-34628-1',
#   }
#
# @example Use a TLS certificate for the web interface
#   class { 'unifi':
#     ssl_certificate => '/etc/ssl/certs/unifi.example.com.pem',
#     ssl_private_key => '/etc/ssl/private/unifi.example.com.key',
#   }
#
# @example Follow a release line in Ubiquiti's APT repository
#   class { 'unifi':
#     install_from   => 'repository',
#     repo_release   => 'unifi-10.4',
#     package_ensure => 'latest',
#   }
#
# @param install_from
#   `download` installs the .deb for `package_ensure` from Ubiquiti's
#   download server; `repository` installs from the APT repository.
# @param package_url
#   The .deb to download. Defaults to Ubiquiti's URL for the version in
#   `package_ensure`.
# @param package_checksums
#   SHA-256 checksums of known .deb files, keyed by package version. A
#   download with a known checksum is verified; others are trusted as
#   downloaded over HTTPS.
# @param download_dir
#   Where the downloaded .deb is kept.
# @param manage_repository
#   Whether to add Ubiquiti's APT repository. Defaults to true only when
#   installing from it.
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
#   The package version, such as `10.6.106-36011-1` (the full Debian version,
#   with the build number). With `install_from => 'repository'` it can also
#   be `installed` or `latest`.
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
#   UniFi's keystore password, which can be `Sensitive`. UniFi only opens its
#   keystore with the default, `aircontrolenterprise`.
# @param data_path
#   UniFi's data directory, where `system.properties` and the keystore live.
# @param settings
#   `unifi::setting` resources to declare, keyed by property name, such as
#   `{ 'unifi.https.port' => { 'value' => '8443' } }`.
# @param manage_defaults
#   Whether to write `/etc/default/unifi`, which the service and the
#   package's scripts read for environment variables.
# @param defaults
#   Variables for `/etc/default/unifi`, such as
#   `{ 'JVM_MAX_HEAP_SIZE' => 2048, 'UNIFI_JVM_EXTRA_OPTS' => '-Dlog4j2.formatMsgNoLookups=true' }`.
#   `JVM_INIT_HEAP_SIZE` and `JVM_MAX_HEAP_SIZE` are in MB.
# @param manage_logrotate
#   Whether to manage `/etc/logrotate.d/unifi`, which rotates the MongoDB log
#   UniFi keeps in its logs directory. UniFi rotates its own `server.log`.
# @param logrotate_rotate
#   How many rotated logs to keep.
# @param logrotate_size
#   Rotate when the log is larger than this, such as `50M`.
# @param logrotate_compress
#   Whether to compress rotated logs.
class unifi (
  # Defaults for these are in the module's Hiera data, per OS.
  Boolean                                  $manage_java_repository,
  String[1]                                $mongodb_repo_location,
  String[1]                                $mongodb_repo_component,
  String[1]                                $mongodb_version,
  Optional[String[1]]                      $java_package,
  String[1]                                $package_ensure,
  Hash[String[1], Pattern[/\A\h{64}\z/]]   $package_checksums,
  Enum['download', 'repository']           $install_from              = 'download',
  Optional[Stdlib::HTTPUrl]                $package_url               = undef,
  Stdlib::Absolutepath                     $download_dir              = '/var/cache/unifi',
  Boolean                                  $manage_repository         = ($install_from == 'repository'),
  Stdlib::HTTPUrl                          $repo_location             = 'https://dl.ui.com/unifi/debian',
  String[1]                                $repo_release              = 'stable',
  String[1]                                $repo_key_name             = 'unifi-repo.gpg',
  Stdlib::HTTPUrl                          $repo_key_source           = 'https://dl.ui.com/unifi/unifi-repo.gpg',
  Boolean                                  $manage_mongodb_repository = true,
  Stdlib::HTTPUrl                          $java_repo_location        = 'https://packages.adoptium.net/artifactory/deb',
  Boolean                                  $manage_package            = true,
  String[1]                                $package_name              = 'unifi',
  Boolean                                  $manage_service            = true,
  String[1]                                $service_name              = 'unifi',
  Stdlib::Ensure::Service                  $service_ensure            = 'running',
  Boolean                                  $service_enable            = true,
  Optional[Stdlib::Absolutepath]           $ssl_certificate           = undef,
  Optional[Stdlib::Absolutepath]           $ssl_private_key           = undef,
  Variant[String[1], Sensitive[String[1]]] $keystore_password         = 'aircontrolenterprise',
  Stdlib::Absolutepath                     $data_path                 = '/var/lib/unifi',
  Hash[String[1], Hash]                    $settings                  = {},
  Boolean                                  $manage_defaults           = false,
  Unifi::Environment                       $defaults                  = {},
  Boolean                                  $manage_logrotate          = true,
  Integer[0]                               $logrotate_rotate          = 5,
  Pattern[/\A\d+[kMG]?\z/]                 $logrotate_size            = '50M',
  Boolean                                  $logrotate_compress        = true,
) {
  unless $facts['os']['family'] == 'Debian' {
    fail("unifi: Ubiquiti only publishes UniFi for Debian and Ubuntu, not ${facts['os']['name']}.")
  }
  if $install_from == 'download' and $package_ensure !~ /\A\d+\.\d+\.\d+-/ {
    fail("unifi: to download UniFi, set package_ensure to a full package version such as '10.6.106-36011-1', not '${package_ensure}'.")
  }

  contain unifi::repo
  contain unifi::install
  contain unifi::config
  contain unifi::service

  Class['unifi::repo']
  -> Class['unifi::install']
  -> Class['unifi::config']
  ~> Class['unifi::service']
}
