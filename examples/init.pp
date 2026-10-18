# The UniFi Network application, with MongoDB and Java from their vendors'
# repositories where the distribution doesn't have them, and a certificate
# for the web interface.
class { 'unifi':
  ssl_certificate => '/etc/ssl/certs/unifi.example.com.pem',
  ssl_private_key => '/etc/ssl/private/unifi.example.com.key',
  settings        => {
    'unifi.https.port' => { 'value' => 8443 },
  },
}
