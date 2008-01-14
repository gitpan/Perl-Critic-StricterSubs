##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.03/t/tlib/HasExports.pm $
#     $Date: 2008-01-13 18:30:52 -0800 (Sun, 13 Jan 2008) $
#   $Author: thaljef $
# $Revision: 2096 $
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
