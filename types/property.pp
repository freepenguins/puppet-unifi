# @summary A key in UniFi's system.properties, such as `unifi.https.port`.
#
# Letters, digits, dots, dashes and underscores, starting with a letter or
# digit. A space, slash or quote would break the Augeas change that sets it.
type Unifi::Property = Pattern[/\A[A-Za-z0-9][A-Za-z0-9._-]*\z/]
