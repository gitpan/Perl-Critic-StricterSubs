#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.03/Build.PL $
#     $Date: 2008-01-13 18:30:52 -0800 (Sun, 13 Jan 2008) $
#   $Author: thaljef $
# $Revision: 2096 $
########################################################################

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(

  module_name    => 'Perl::Critic::StricterSubs',
  dist_author    => 'Jeffrey Thalhammer <thaljef@cpan.org>',
  dist_abstract  => 'Perl::Critic plugin for stricter subroutine checking',
  license        => 'perl',

  requires       => {'Perl::Critic'              => 1.080,
                     'Perl::Critic::Utils'       => 1.080,
                     'Perl::Critic::Violation'   => 1.080,
                     'Perl::Critic::TestUtils'   => 1.080,
                     'File::PathList'            => 0,
                    },

  build_requires => {'Test::More'                => 0,
                     'Test::Deep'                => 0,
                    },

);

$builder->create_build_script();
