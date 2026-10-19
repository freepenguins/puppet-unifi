# Give UniFi more Java heap through /etc/default/unifi (sizes in MB), for a
# controller with many devices. The service restarts when the file changes.
class { 'unifi':
  manage_defaults => true,
  defaults        => {
    'JVM_INIT_HEAP_SIZE' => 1024,
    'JVM_MAX_HEAP_SIZE'  => 4096,
  },
}
