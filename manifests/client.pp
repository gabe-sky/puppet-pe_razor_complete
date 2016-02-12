# This simple class just makes sure the pe-razor-client gem is installed.  This
# provides the `razor` command line interface.

class pe_razor_complete::client {

  # In case someone else is managing ruby and gems on this system, we'll use
  # ensure_packages from the stdlib to be safe about trying to manage them.
  # But we do need them to be installed.
  ensure_packages( ['ruby','rubygems'], {'ensure' => 'installed' } )

  # The razor command line tool is just a ruby gem.
  package { 'pe-razor-client':
    ensure   => installed,
    provider => gem,
  }

}
