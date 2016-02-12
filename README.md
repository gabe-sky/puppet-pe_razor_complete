# PE Razor Complete

The purpose of this module is to provide a quick "profile" module that sets up a dual-homed PUPPET ENTERPRISE managed Razor server, including a DHCP service on a secondary (eth1 by default) interface -- and also adds a corresponding tftp service to serve an iPXE kernel.  Network-booting machines will use those services, and be controlled by Razor.

This module is intended to assist in learning Razor, by making it super-simple to try out a dual-homed Razor server, presumably in a lab with a dedicated VLAN for the DHCP and other provisioning communication.

This module relies on four others.  One is the pe_razor module, which a Puppet Enterprise master already has installed.  The other three are:

  * nanliu-staging
  * puppetlabs-firewall
  * puppetlabs-stdlib

This module only works if your Master is running Puppet Enterprise.  If you're just messing around, it's very easy to install an Enterprise Master, and it comes with a free license for up to 10 machines.

If you're using Open Source Puppet, I heartily recommend looking at the lavaburn/razor module on the Puppet Forge.  It's excellent, and has additional types and providers that go way beyond this module's "set it up and run away" attitude.


## Basic CentOS 6 Example

With CentOS 6 and a Puppet Enterprise master, you should be able to just do this:
  1. Attach eth0 to a network so that you can SSH in to the machine.
  1. Attach eth1 to a "provisioning" network where it's okay for it to run DHCP.
  1. Statically assign eth1 to an IP in the default DHCP server's 10.11.12.0/24 range where it will give out leases.
  1. Apply this class to the node.

```puppet
include pe_razor_complete
```

You should now be able to network-boot bare machines on the "provisioning" network and have them boot the microkernel and report in to the Razor server.


## Specify a different IP range for the provisioning network.

If for some reason you'd like nodes to receive a different range of DHCP leases, different netmask, and even lease time, you can declare the class with some extra parameters.

```puppet
class { 'pe_razor_complete':
  dnsmasq_dhcp_start => '192.168.192.128',
  dnsmasq_dhcp_end   => '192.168.192.196',
  dnsmasq_dhcp_mask  => '255.255.255.0',   # the default, actually
  dnsmasq_dhcp_lease => '2d',
}
```


## Non-eth1 Provisioning Network Example

If you're brave enough to let the server handle DHCP requests on its primary interface, or if you're on a CentOS 7 system where the nic names are wacky, declare it with a parameter to have DHCP and other provisioning communication done over something other than eth1:

```puppet
class { 'pe_razor_complete':
  dnsmasq_interface => 'eth0',
}
```
