
class pe_razor_complete::dhcp (
  $dnsmasq_dhcp_start     = $pe_razor_complete::dnsmasq_dhcp_start,
  $dnsmasq_dhcp_end       = $pe_razor_complete::dnsmasq_dhcp_end,
  $dnsmasq_dhcp_netmask   = $pe_razor_complete::dnsmasq_dhcp_netmask,
  $dnsmasq_dhcp_lease     = $pe_razor_complete::dnsmasq_dhcp_lease,
  $dnsmasq_interface      = $pe_razor_complete::dnsmasq_interface,
) inherits pe_razor_complete {

  # Make sure dnsmasq is installed and running, so it can do dhcp and tftp.
  package { 'dnsmasq':
    ensure => installed,
  }
  service { 'dnsmasq':
    ensure => running,
    enable => true,
    require => Package['dnsmasq'],
  }

  # Add the most basic of configuration, we'll update dnsmasq's main config file
  # to limit it to listening on our "provisioning" NIC, and to hand out leases
  # in a limited range.  This is also where we'll tell it to look in dnsmasq.d
  # for additional files, which will set up specific things like pxe booting.
  file { '/etc/dnsmasq.conf':
    ensure => file,
    content => template('pe_razor_complete/dnsmasq.conf.erb'),
    notify => Service['dnsmasq'],
  }

}