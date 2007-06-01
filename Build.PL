#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.02/Build.PL $
#     $Date: 2007-06-01 01:14:14 -0700 (Fri, 01 Jun 2007) $
#   $Author: thaljef $
# $Revision: 1559 $
########################################################################

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(

  module_name    => 'Perl::Critic::StricterSubs',
  dist_author    => 'Jeffrey Thalhammer <thaljef@cpan.org>',
  dist_abstract  => 'Perl::Critic plugin for stricter subroutine checking',
  license        => 'perl',

  requires       => {'Perl::Critic'              => 1.052,
                     'Perl::Critic::Utils'       => 1.052,
                     'Perl::Critic::Violation'   => 1.052,
                     'Perl::Critic::TestUtils'   => 1.052,
                     'File::PathList'            => 0,
                    },

  build_requires => {'Test::More'                => 0,
                     'Test::Deep'                => 0,
                    },

);

$builder->create_build_script();
