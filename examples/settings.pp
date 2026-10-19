# Set properties in UniFi's system.properties. Each change restarts UniFi.
class { 'unifi':
  settings => {
    'unifi.http.port'  => { 'value' => 8081 },
    'unifi.https.port' => { 'value' => 8443 },
  },
}

# The same thing as a resource, here removing a property.
unifi::setting { 'portal.http.port':
  ensure => absent,
}
