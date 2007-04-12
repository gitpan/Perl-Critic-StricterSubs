##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-StricterSubs/lib/Perl/Critic/Policy/Modules/ProhibitExportingUndeclaredSubs.pm $
#     $Date: 2007-04-06 11:58:16 -0700 (Fri, 06 Apr 2007) $
#   $Author: thaljef $
# $Revision: 1391 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs;

use strict;
use warnings;
use Carp qw(croak);
use base 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(
    &hashify
    :severities
);

use Perl::Critic::StricterSubs::Utils qw( &find_exported_sub_names );

#-----------------------------------------------------------------------------

our $VERSION = 0.01;

#-----------------------------------------------------------------------------

sub supported_parameters { return }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $doc) = @_;
    my @exported_sub_names = find_exported_sub_names( $doc );
    my @declared_sub_names = _find_declared_sub_names( $doc );
    my %declared_sub_names = hashify( @declared_sub_names );
    my @violations = ();

    for my $sub_name ( @exported_sub_names ) {
        if ( not exists $declared_sub_names{ $sub_name } ){
            my $msg = qq{Subroutine "$sub_name" is exported but not declared};
            my $desc = qq{Perhaps you forgot to define "$sub_name"};
            push @violations, $self->violation( $msg, $desc, $doc );
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _find_declared_sub_names {
    my ($doc) = @_;
    my $sub_nodes = $doc->find('PPI::Statement::Sub');
    return if not $sub_nodes;

    my @sub_names = map { $_->name() } @{ $sub_nodes };
    for (@sub_names) { s{\A .*::}{}mx };  # Remove leading package name
    return @sub_names;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitExportingUndeclaredSubs

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

This Policy checks that any subroutine listed in C<@EXPORT> or C<@EXPORT_OK>
is actually defined in the current file.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
