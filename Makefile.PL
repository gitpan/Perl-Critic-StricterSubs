#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.01/Makefile.PL $
#     $Date: 2007-04-12 01:12:30 -0700 (Thu, 12 Apr 2007) $
#   $Author: thaljef $
# $Revision: 1464 $
########################################################################

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile( NAME           => 'Perl::Critic::StricterSubs',
               AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
               ABSTRACT_FROM  => 'lib/Perl/Critic/StricterSubs.pm',
               VERSION_FROM   => 'lib/Perl/Critic/StricterSubs.pm',
               PL_FILES       => {},
               PREREQ_PM      => {'Perl::Critic'            => 1.51,
                                  'Perl::Critic::Utils'     => 1.51,
                                  'Perl::Critic::Violation' => 1.51,
                                  'Perl::Critic::TestUtils' => 1.51,
                                  'Test::More'              => 0,
                                  'Test::Deep'              => 0,
                                  'File::PathList'          => 0,
                              },

);
