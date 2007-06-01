##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.02/t/tlib/HasExports.pm $
#     $Date: 2007-06-01 01:14:14 -0700 (Fri, 01 Jun 2007) $
#   $Author: thaljef $
# $Revision: 1559 $
##############################################################################

package HasExports;

use base 'Exporter';

our @EXPORT = qw(
    &sub1
    sub2
    $scalar
    %hash
    @array
);

our @EXPORT_OK = (
    '&ok_sub1',
    'ok_sub2',
    '$ok_scalar',
    '%ok_hash',
    '@ok_array'
);

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
