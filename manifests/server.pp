# This class simply declares the pe_razor class without any parameters.  If you
# want to specify parameters for the pe_razor class, the official way is to
# do that in the Enterprise Console.  Look in the PE Razor classification group
# for that.

class pe_razor_complete::server {

  # Use the pe_razor module that's included with Puppet Enterprise
  include pe_razor

}
