# PE Razor Complete

The purpose of this module is to provide a quick "profile" module that sets up a dual-homed PUPPET ENTERPRISE Razor server, including a DHCP service on a secondary (eth1 by default) interface, and corresponding tftp service to serve an iPXE kernel to network-booting machines so that they will registered with the Razor server.

It is intended to assist in learning Razor, by making it super-simple to try out a dual-homed Razor server, presumably in a lab with a dedicated VLAN for the DHCP and other provisioning communication.

## Basic CentOS 6 Example

With CentOS 6 and a Puppet Enterprise master, you should be able to just do this:
  1. Attach eth0 to a network so that you can SSH in to the machine.
  1. Attach eth1 to a "provisioning" network where it's okay for it to run DHCP.
  1. Statically assign eth1 to an IP in the default DHCP server's 10.11.12.0/24 range where it will give out leases.
  1. Apply this class to the node.

````
include pe_razor_complete
````

You should now be able to network-boot bare machines on the "provisioning" network and have them boot the microkernel and report in to the Razor server.

## Specify a different IP range for the provisioning network.

If for some reason you'd like nodes to receive a different range of DHCP leases, different netmask, and even lease time, declare the class with some extra parameters.

````
class { 'pe_razor_complete':
  dnsmasq_dhcp_start => '192.168.192.128',
  dnsmasq_dhcp_end   => '192.168.192.196',
  dnsmasq_dhcp_mask  => '255.255.255.0',   # the default, actually
  dnsmasq_dhcp_lease => '2d',
}
````

## Non-eth1 Provisioning Network Example

If you're brave enough to let the server handle DHCP requests on its primary interface, or if you're on a CentOS 7 system where the nic names are wacky, declare it with a parameter to have DHCP and other provisioning communication done over something other than eth1:

````
class { 'pe_razor_complete':
  dnsmasq_interface => 'eth0',
}
````

