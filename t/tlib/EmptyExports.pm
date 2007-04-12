##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.01/t/tlib/EmptyExports.pm $
#     $Date: 2007-04-12 01:12:30 -0700 (Thu, 12 Apr 2007) $
#   $Author: thaljef $
# $Revision: 1464 $
##############################################################################


package EmptyExports;

use base 'Exporter';

our @EXPORT = ();
our @EXPORT_OK;

1;


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
