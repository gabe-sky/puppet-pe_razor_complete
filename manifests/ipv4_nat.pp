
class pe_razor_complete::ipv4_nat (
  $ipv4_nat_outiface = $pe_razor_complete::ipv4_nat_outiface,
) inherits pe_razor_complete {

  # Update the sysctl config to forward traffic, and restart the network service
  service { 'network':
    subscribe => File_line['ipv4.forward'],
  }
  file_line { 'ipv4.forward':
    path  => '/etc/sysctl.conf',
    line  => 'net.ipv4.ip_forward = 1',
    match => '^net.ipv4.ip_forward = [01]',
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
