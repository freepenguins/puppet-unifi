# Keep more, larger MongoDB logs than the package's 5 x 50M.
class { 'unifi':
  logrotate_rotate => 14,
  logrotate_size   => '200M',
}
