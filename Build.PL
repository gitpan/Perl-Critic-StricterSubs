#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.01/Build.PL $
#     $Date: 2007-04-12 01:12:30 -0700 (Thu, 12 Apr 2007) $
#   $Author: thaljef $
# $Revision: 1464 $
########################################################################

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(

  module_name    => 'Perl::Critic::StricterSubs',
  dist_author    => 'Jeffrey Thalhammer <thaljef@cpan.org>',
  dist_abstract  => 'Perl::Critic plugin for stricter subroutine checking',
  license        => 'perl',

  requires       => {'Perl::Critic'              => 1.051,
                     'Perl::Critic::Utils'       => 1.051,
                     'Perl::Critic::Violation'   => 1.051,
                     'Perl::Critic::TestUtils'   => 1.051,
                     'File::PathList'            => 0,
                    },

  build_requires => {'Test::More'                => 0,
                     'Test::Deep'                => 0,
                    },

);

$builder->create_build_script();
