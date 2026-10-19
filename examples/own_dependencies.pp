# Leave MongoDB and Java to something else, such as your own repositories or
# profiles, and only install UniFi.
class { 'unifi':
  manage_mongodb_repository => false,
  manage_java_repository    => false,
  java_package              => undef,
}
