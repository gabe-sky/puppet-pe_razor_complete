
class pe_razor_complete::client {

  # In case someone else is managing ruby and gems on this system, we'll use
  # ensure_packages from the stdlib to be safe about trying to manage them.
  ensure_packages( ['ruby','rubygems'], {'ensure' => 'installed' } )

  # The razor command line tool is in a ruby gem.
  package { 'pe-razor-client':
    ensure   => installed,
    provider => gem,
  }

}
