# @summary Runs the UniFi service.
#
# @api private
class unifi::service {
  assert_private()

  if $unifi::manage_service {
    service { $unifi::service_name:
      ensure => $unifi::service_ensure,
      enable => $unifi::service_enable,
    }
  }
}
