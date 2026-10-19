# Serve the web interface with your own certificate, for example from Let's
# Encrypt. The certificate (with its chain) and key are PEM files on the host;
# UniFi restarts when they change.
class { 'unifi':
  ssl_certificate   => '/etc/ssl/certs/unifi.example.com.pem',
  ssl_private_key   => '/etc/ssl/private/unifi.example.com.key',
  keystore_password => Sensitive('aircontrolenterprise'),
}
