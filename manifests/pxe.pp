
class pe_razor_complete::pxe (
) inherits pe_razor_complete {

  # Enable the dnsmasq tftp server, and aim it at /var/lib/tftpboot for files.
  file { '/etc/dnsmasq.d/tftp':
    ensure  => file,
    content => template('pe_razor_complete/tftp.erb'),
    require => Package['dnsmasq'],
    notify  => Service['dnsmasq'],
  }
  file { '/var/lib/tftpboot':
    ensure => directory,
    before => Service['dnsmasq'],
  }

  # New nodes will be told to boot the iPXE (undionly) kernel.
  staging::file { 'undionly.kpxe':
   target  => "/var/lib/tftpboot/undionly.kpxe",
   source  => 'https://s3.amazonaws.com/pe-razor-resources/undionly-20140116.kpxe',
   require => [ File['/var/lib/tftpboot'], Class['pe_razor'] ],
  }

  # The iPXE kernel will fetch a bootstrap.ipxe file, that then aims a chain
  # loader at the Razor server to determine how to proceed.  For instance, new
  # machines are simply told to load a microkernel.
  # The bootstrap is static, but Razor likes to be the one to craft it.
  staging::file { 'bootstrap.ipxe':
    target  => "/var/lib/tftpboot/bootstrap.ipxe",
    source  => "https://${facts['networking']['interfaces'][$dnsmasq_interface]['ip']}:8151/api/microkernel/bootstrap?nic_max=1&http_port=8150",
    curl_option => '--insecure',
    require => [ File['/var/lib/tftpboot'], Class['pe_razor'] ],
  }

  # Supply just enough dhcp configuration so that all network-booting machines
  # are instructed to load the iPXE (undionly) kernel.  And when the iPXE kernel
  # requests configuration from dhcp, it gets aimed at the bootstrap.ipxe file.
  file { '/etc/dnsmasq.d/ipxe':
    ensure  => file,
    content => template('pe_razor_complete/ipxe.erb'),
    require => Package['dnsmasq'],
    notify  => Service['dnsmasq'],
  }

}
