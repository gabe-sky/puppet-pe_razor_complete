# This class enabled IPv4 forwarding on the Razor server, and configures the
# firewall with a NAT rule.  This allows machines in the DHCP range to reach
# "outside" machines by using the Razor server as a router.
#
# This is not specifically required for Razor to be able to provision machines,
# but the convenience is very handy when learning how Razor works.  For
# instance, this allows machines in the DHCP range to reach external sources
# of packages.  Otherwise you would need copies that are local to the DHCP
# network.

class pe_razor_complete::ipv4_nat (
  $ipv4_nat_outiface = $pe_razor_complete::ipv4_nat_outiface,
) inherits pe_razor_complete {

  # Update the sysctl config to forward traffic, and restart the network service
  file_line { 'ipv4.forward':
    path  => '/etc/sysctl.conf',
    line  => 'net.ipv4.ip_forward = 1',
    match => '^net.ipv4.ip_forward = [01]',
  }
  service { 'network':
    subscribe => File_line['ipv4.forward'],
  }

  # Add a rule to masquerade traffic from the dhcp side to the upstream.
  include firewall
  firewall { '100 masquerate traffic from the dhcp interface':
    chain     => 'POSTROUTING',
    jump      => 'MASQUERADE',
    proto     => 'all',
    outiface  => $ipv4_nat_outiface,
    src_range => "${dnsmasq_dhcp_start}-${dnsmasq_dhcp_end}",
    table     => 'nat',
  }

}
