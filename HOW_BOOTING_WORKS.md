# How Booting Works

Setting up the proper booting environment can be filed under "hard to do ... the first time."  If you need to debug a Razor environment -- whether or not your Razor server is responsible for DHCP, tftp, and iPXE -- it's useful to know what's actually going on when a node does a network-boot in a Razor environment.


## Simplified

Totally simplified, a new node booting does this:

  1. DCHP assigns an address and says to fetch an iPXE (undionly.kpxe) kernel over tftp.
  1. iPXE kernel boots and is told to fetch further instructions (bootstrap.ipxe) over tftp.
  1. bootstrap.ipxe says to fetch instructions for what kernel and initrd to boot by querying the Razor API over http on port 8150.
  1. Razor says what to boot based on whether it knows the node, and whether it has a task assigned to it.
  1. Unknown nodes boot the Razor microkernel and report in to Razor.
  1. Once Razor knows what to do with a node, reboot into an installer.
  1. Once an OS is installed, subsequent iPXE instructions from Razor are to boot to disk.


## Less Simplified

Less-but-still simplified, the blow-by-blow of what happens when a new node boots is this:

  1. Make a DHCP request for IP address and "next server" to get an OS from.
  1. Receive an IP address, and instructions to boot the iPXE (undionly.kpxe) kernel.
  1. Retrieve the iPXE kernel via tftp.
  1. Boot the iPXE kernel.
  1. The kernel makes a second DHCP request with option 175 set, identifying the request as being from the iPXE kernel.
  1. Receive an IP address, and instructions that the iPXE kernel should fetch bootstrap.ipxe.
  1. Retrieve bootstrap.ipxe via tftp and execute it.
  1. Bootstrap instructs iPXE to fetch booting instructions from the Razor server.
  1. iPXE crafts a custom request to the Razor server including basics like MAC address.
  1. iPXE requests instructions over http port 8150 about what initrd and kernel to chain boot into.
  1. iPXE chains to whatever initrd and kernel Razor said to.
    1.1 (Since this is a new and unknown machine, boot the microkernel.)
  1. The system boots a CentOS 7-based "microkernel," including extra kernel boot-line parameters that identify where the Razor server is.
  1. Once up, the microkernel runs facter and posts its facts to the Razor server API over http on port 8150.
  1. If the Razor server has no further instructions, the microkernel waits a configurable number of seconds, and then re-posts its facts to the Razor API.
  1. This repeats until the Razor server actually has a task assigned to the node.
  1. The Razor server replies to the next post of facts with the instruction to reboot.
  1. On the second reboot, iPXE loads, gets the bootstrap as usual, but when the bootstrap crafts a request to the API for what initrd and kernel to boot, it is told to boot into, e.g., do a kickstart or Windows CE provisioning.
  1. The chain loader takes those instructions an chains into them.
  1. The OS is installed as usual, and rebooted.
  1. Upon reboot, iPXE loads, gets the bootstrap as usual, and when it asks where to chain boot into, it's told to use the local disk.
    1.1 (Or, if its role has changed, chain into a different installer.)


## Down the Rabbit Hole

