# @summary Sets or removes a property in UniFi's system.properties.
#
# UniFi reads `system.properties` when it starts, so a change restarts the
# service (when the module manages it).
#
# @example Move the device inform port
#   unifi::setting { 'unifi.http.port':
#     value => '8081',
#   }
#
# @example Remove a property
#   unifi::setting { 'unifi.https.port':
#     ensure => absent,
#   }
#
# @param ensure
#   `present` sets the property to `value`; `absent` removes it.
# @param value
#   The property's value. Required unless `ensure` is `absent`.
# @param property
#   The property name. Defaults to the resource title.
define unifi::setting (
  Enum['present', 'absent']                    $ensure   = 'present',
  Optional[Variant[String, Integer, Boolean]] $value    = undef,
  String[1]                                    $property = $title,
) {
  if $ensure == 'present' and $value =~ Undef {
    fail("unifi::setting[${title}]: set a value, or ensure => absent.")
  }

  $changes = $ensure ? {
    'present' => "set ${property} '${String($value).regsubst("'", "\\\\'", 'G')}'",
    'absent'  => "rm ${property}",
  }

  augeas { "unifi-setting-${property}":
    incl    => "${unifi::data_path}/system.properties",
    lens    => 'Properties.lns',
    changes => $changes,
    require => Class['unifi::install'],
    notify  => Class['unifi::service'],
  }
}
