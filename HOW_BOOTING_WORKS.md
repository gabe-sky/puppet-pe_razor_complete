# How Booting Works

Setting up the proper booting environment can be filed under "hard to do ... the first time."  If you need to debug a Razor environment -- whether or not your Razor server is responsible for DHCP, tftp, and iPXE -- it's useful to know what's actually going on when a node does a network-boot in a Razor environment.

These notes are Linux-centric.  If you're provisioning Windows, there is an extra chain-loader step.  iPXE can hand-off to a Linux initrd/vmlinuz installer by itself, but for Windows hand-off, it chains into yet another boot loader which then boots into an installer.

These notes are PXE firmware centric.  The iPXE site actually has a native EUFI kernel.  However, they note that most UEFI systems will pretend to be a PXE firmware, and will happily use the PXE (undionly.kpxe) kernel.  So you don't have to get fancy unless you have fascist UEFI firmwares running amok.


## Simplified

Totally simplified, a new node booting does this:

  1. DCHP assigns an address and says to fetch an iPXE (undionly.kpxe) kernel over tftp.
  1. iPXE kernel boots and is told to fetch further instructions (bootstrap.ipxe) over tftp.
  1. bootstrap.ipxe says to fetch instructions for what kernel and initrd to boot by querying the Razor API over http on port 8150.
  1. Razor says what to boot based on whether it knows the node, and whether it has a policy bound to it.
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
    1. (Since this is a new and unknown machine, boot the microkernel.)
  1. The system boots a CentOS 7-based "microkernel," including extra kernel boot-line parameters that identify where the Razor server is.
  1. Once up, the microkernel runs facter and posts its facts to the Razor server API over http on port 8150.
  1. If the Razor server has no further instructions, the microkernel waits a configurable number of seconds, and then re-posts its facts to the Razor API.
  1. This repeats until the Razor server actually has a policy bound to the node.
  1. The Razor server replies to the next post of facts with the instruction to reboot.
  1. On the second reboot, iPXE loads, gets the bootstrap as usual, but when the bootstrap crafts a request to the API for what initrd and kernel to boot, it is told to boot into, e.g., do a kickstart or Windows CE provisioning.
  1. The chain loader takes those instructions and chains into them.
  1. The OS is installed as usual, and rebooted.
  1. Upon reboot, iPXE loads, gets the bootstrap as usual, and when it asks where to chain boot into, it's told to use the local disk.
    1. (Or, if its role has changed, chain into a different installer.)


## Down the Rabbit Hole

You asked for the Red Pill.


### First Boot

The machine's BIOS' PXE system gets on the network and broadcasts a request for DHCP configuration.  The initial request should have option 53 set, indicating that this is plain-old boring dicover/offer/request/ack.

The DHCP server also tells the client where the tftp server is (66), and what filename to request from it (67).  Using this Puppet module with default parameters, the tftp server is the Razor server's DHCP interface's address.  And the filename is the iPXE (undionly.kpxe) kernel.

This request is broadcast traffic over UDP from port 67 to port 67 -- and the reply is from UDP port 68 to port 68.  So, if you have a paranoid firewall on your DHCP server, it may be blocking either the broadcast source or broadcast destination.  Oddly, dnsmasq seems to have issues with the stock CentOS 6 and 7 firewalls, while ISC DHCP sees the traffic despite the firewall.

The wikipedia page is pretty thorough about how DCHP works -- https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol.

The wikipedia page on PXE is informative -- https://en.wikipedia.org/wiki/Preboot_Execution_Environment

### Load the iPXE Kernel

There is fantastic documentation on what happens when PXE chain loads an iPXE kernel, here -- http://ipxe.org/howto/chainloading

This Puppet module sets up dnsmasq to make the chain loading happen -- but the iPXE site has examples for what to do to get ISC DHCP to do the same thing -- so go there if you need to have a different type of DHCP server do all the instructing.

Instructed by DHCP's options 66 and 67, the machine fetches tftp://razor-server/undionly.kpxe.

The PXE system loads the iPXE code into the machine's memory and tells the CPU to execute it.  Talk about hiring your own replacement.  Note, PXE is on the NIC, and iPXE ends up in RAM.  Also note, some cards have been (re)flashed to have iPXE in the NIC's firmware instead of PXE.  I don't know how this would impact Razor.  In theory, it would just mean you skip the PXE link in the chain, and iPXE gets the instructions to grab bootstrap.ipxe as usual.  No problem.


### Receive iPXE Configuration

iPXE now re-requests DHCP information.  This second DHCP request has the RFC 3004 "user-class" option (77) set to "iPXE".  And it also has an iPXE-specific DHCP option, ipxe-encap-opts (175) set.

Absent additional configuration, the DHCP server would just tell the iPXE kernel to chain boot into the iPXE kernel, which would tell the iPXE kernel to chain boot into the iPXE kernel.  It's turtles all the way down.

Depending on your DHCP server, you need to detect that it's iPXE requesting a configuration.  In this Puppet module, we have dnsmasq simply check for the presence of the ipxe-encap-opts (175) in the request.  The recommended scheme for dealing with ISC DHCP is to have it look at the user-class (77) option and see if it says "iPXE."

The DHCP server sends a different tftp server (66) and filename (67) answer to iPXE.  It instructs the kernel to download tftp://razor-server/bootstrap.ipxe and interpret it.

The iPXE kernel requests the file and begins to interpret it.  Note that it is not loading this into RAM.  You can actually just open up the bootstrap.ipxe file and see what it's telling the iPXE kernel to do.


### iPXE Interprets bootstrap.ipxe

If you look in the Puppet code of this module, you'll see that the bootstrap.ipxe file is not actually a static file resource, but the result of an http request over port 8150 to the Razor server's API.  This file's contents were generated by the API.  Its contents won't change unless you move the Razor server, so it's safe for our Puppet code to just fetch it once, and leave it be, once it exists.

If you take a look inside the bootstrap.ipxe file, the important part is the 'chain' instruction.  The iPXE kernel is crafting a custom request to the Razor server, which includes in the URL the mac address (and more) of the hardware that it's running on.

The Razor server uses this information to decide what to tell iPXE to chain boot into next.  Assuming this is a brand new machine, or at least one that Razor doesn't know what to do with, the instructions to the chain loader are to boot the microkernel.  Y can craft a dummy query to the Razor server to see what it looks like (note: this will actually create a node object in the Razor server -- it looks "real"):

  wget http://10.11.12.3:8150/svc/boot?net0=00-01-02-03-04-05 -O -

iPXE is able to natively chain into a Linux boot.  And for a newly discovered machine, that's exactly what the Razor server just told it to do.


### Boot with initrd and vmlinuz Generated by Razor

If you take a look inside the Razor server's response to the bootstrap.ipxe request, you'll see that it's instructing the chain loader to use an initrd and vmlinuz kernel fetched right off the Razor server's http port 8150.

For your first boot, these are the microkernel's disk and kernel. That's part of why the Razor install took so long -- it was downloading hundreds of megs of image so that it can serve them from itself.

On subsequent boots, once a machine has a policy bound to it, the Razor server will be instructing bootstrap.ipxe to boot from different initrd and vmlinuz files, also fetcheed over http port 8150, right from the Razor server.  Those are your 'repositories' that you'll set up to install various systems.  But for the first boot it's the microkernel.


### Boot the Microkernel

Both initial ramdisk and kernel are fetched right from the Razor server over http on port 8150.  Be aware that the "micro" kernel is actually pretty hefty, around 150 Mb, so make sure you're prepared to have that much traffic going over your network.  In a lab environment it's fine, but if your customer is reprovisioning an HPC environment all at once, it's going to get a little slow.

The microkernel is based on CentOS 7 with all of the extra stuff stripped out.It's so bare-bones you don't even have `less` available -- just good old-fashioned `more` to reminisce with.


### Wait for Instructions

Once it's up and running, the microkernel repeatedly runs `facter` and submits its facts to the Razor server.  Take a second look at the Razor server's kernel line when bootstrap.ipxe asked it what image and kernel to boot.  The kernel line has extra parameters so that the microkernel knows where to submit its facts.

The mechanism where facts are posted to the Razor server's API is actually a real systemd service definition.  The service definition says to run the service every fifteen seconds.  And to exec the service, run `/usr/local/bin/mk-update register`.  Note, the systemd definitions and scripts are baked in to the image, so if you want to change the register interval, you'd need to rebuild the microkernel disk image.

If no policy has been bound to this node yet, the mk-update command just keeps running and doing nothing.  Once a policy is bound to the node, mk-update recieves an "update" which tells it what to do next.

Additionally, while the mk-update task is waiting, the Razor server can send it additional Facts to extend facter.  Thus, a node is not restricted to just registering with built-in facts .. you can distribute custom facts to a node as well.

Eventually, the node is instructed reboot.  Now iPXE's bootstrap.ipxe script fetches a new dynamically-generated chain loader configuration from the Razor server.  Likely, this looks like a normal kickstart's ramdisk and kernel line, with kernel and ramdisk fetched off the Razor server -- as well as using a repository on the Razor server to fetch installation files.


### After the OS is Provisioned

Once the system has an OS installed, it is advisable to leave it configured for a network boot.  When bootstrap.ipxe asks the Razor server what the chain loader should do, the dynamically-generated reply will be to boot from the local disk.

Should a different policy be bound to this machine in the future, and Razor instructed to reprovision it, the Razor server's reply to the bootstrap.ipxe's request for chain loader instructions will aim the machine at a new kernel and ramdisk so that a new OS can be installed on the system.
