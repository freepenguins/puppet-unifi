# @summary Configures UniFi: its keystore, settings, environment and log rotation.
#
# @api private
class unifi::config {
  assert_private()

  # UniFi reads its web interface's certificate from the `unifi` entry of
  # its Java keystore.
  if $unifi::ssl_certificate and $unifi::ssl_private_key {
    java_ks { "unifi:${unifi::data_path}/keystore":
      ensure      => latest,
      certificate => $unifi::ssl_certificate,
      private_key => $unifi::ssl_private_key,
      password    => $unifi::keystore_password,
    }
  } elsif $unifi::ssl_certificate or $unifi::ssl_private_key {
    fail('unifi: set both ssl_certificate and ssl_private_key, or neither.')
  }

  # Properties in system.properties.
  $unifi::settings.each |String[1] $name, Hash $params| {
    unifi::setting { $name:
      * => $params,
    }
  }

  # Environment for the service (systemd's EnvironmentFile) and the
  # package's init and maintainer scripts (which source it as shell).
  if $unifi::manage_defaults {
    file { '/etc/default/unifi':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp("${module_name}/default.epp", { 'variables' => $unifi::defaults }),
    }
  }

  # Replaces the package's own file (the same rules by default), which
  # rotates the MongoDB log UniFi runs. UniFi rotates server.log itself.
  if $unifi::manage_logrotate {
    file { '/etc/logrotate.d/unifi':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp("${module_name}/logrotate.epp", {
        'rotate'   => $unifi::logrotate_rotate,
        'size'     => $unifi::logrotate_size,
        'compress' => $unifi::logrotate_compress,
      }),
    }
  }
}
