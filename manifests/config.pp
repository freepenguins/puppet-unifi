# @summary Imports a TLS certificate into UniFi's keystore.
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
}
