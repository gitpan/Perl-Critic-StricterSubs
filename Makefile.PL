#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.02/Makefile.PL $
#     $Date: 2007-06-01 01:14:14 -0700 (Fri, 01 Jun 2007) $
#   $Author: thaljef $
# $Revision: 1559 $
########################################################################

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( NAME           => 'Perl::Critic::StricterSubs',
               AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
               ABSTRACT_FROM  => 'lib/Perl/Critic/StricterSubs.pm',
               VERSION_FROM   => 'lib/Perl/Critic/StricterSubs.pm',
               PL_FILES       => {},
               PREREQ_PM      => {'Perl::Critic'            => 1.052,
                                  'Perl::Critic::Utils'     => 1.052,
                                  'Perl::Critic::Violation' => 1.052,
                                  'Perl::Critic::TestUtils' => 1.052,
                                  'Test::More'              => 0,
                                  'Test::Deep'              => 0,
                                  'File::PathList'          => 0,
                              },

);
