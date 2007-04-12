##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-StricterSubs/lib/Perl/Critic/Policy/Modules/ProhibitCallsToUnexportedSubs.pm $
#     $Date: 2007-04-10 17:56:54 -0700 (Tue, 10 Apr 2007) $
#   $Author: clonezone $
# $Revision: 1439 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitCallsToUnexportedSubs;

use strict;
use warnings;
use base 'Perl::Critic::Policy';

use PPI::Document;
use File::PathList;

use Perl::Critic::Utils qw(
    &hashify
    &is_function_call
    &is_perl_builtin
    &policy_short_name
    :characters
    :severities
);

use Perl::Critic::StricterSubs::Utils qw{
    &find_exported_sub_names
};

#-----------------------------------------------------------------------------

our $VERSION = 0.01;

#-----------------------------------------------------------------------------

my $CONFIG_PATH_SPLIT_REGEX = qr/ \s* [|] \s* /xms;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return qw( at_inc_prefix use_standard_at_inc at_inc_suffix );
}

sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub new {
    my ( $class, %config ) = @_;
    my $self = bless {}, $class;

    my @at_inc_prefix;
    my @at_inc_suffix;

    if ( defined $config{at_inc_prefix} ) {
        @at_inc_prefix =
            split $CONFIG_PATH_SPLIT_REGEX, $config{at_inc_prefix};
    }
    if ( defined $config{at_inc_suffix} ) {
        @at_inc_prefix =
            split $CONFIG_PATH_SPLIT_REGEX, $config{at_inc_suffix};
    }

    my $use_standard_at_inc = $config{use_standard_at_inc};
    if (not defined $use_standard_at_inc) {
        $use_standard_at_inc = 1;
    }

    my @inc = @at_inc_prefix;
    if ($use_standard_at_inc) {
        push @inc, @INC;
    }
    push @inc, @at_inc_suffix;

    die policy_short_name(__PACKAGE__), " has no directories in its module search path.\n"
        if not @inc;


    $self->{_inc} = File::PathList->new( paths => \@inc, cache => 1 );
    return $self;
}

#-----------------------------------------------------------------------------

sub _get_inc {
    my $self = shift;
    return $self->{_inc};
}

#-----------------------------------------------------------------------------

sub violates {
    my ($self, undef, $doc) = @_;

    my @violations   = ();
    my %export_cache = ();
    my $expl = q{Violates encapsulation};

    for my $sub_call ( _get_qualified_subroutine_calls($doc) ) {

        my ($package, $sub_name)  = $self->_parse_subroutine_call( $sub_call );
        next if _is_builtin_package( $package );

        $export_cache{$package} ||= $self->_get_exports_for_package($package);
        if ( not exists $export_cache{ $package }->{ $sub_name } ){

            my $desc = qq{Subroutine "$sub_name" not exported by "$package"};
            push @violations, $self->violation( $desc, $expl, $sub_call );
        }

    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _parse_subroutine_call {
    my ($self, $sub_call) = @_;
    return if not $sub_call;

    my $sub_name     = $EMPTY;
    my $package_name = $EMPTY;

    if ($sub_call =~ m/ \A &? (.*) :: ([^:]+) \z /xms) {
        $package_name = $1;
        $sub_name = $2;
    }

    return ($package_name, $sub_name);
}


#-----------------------------------------------------------------------------

sub _get_exports_for_package {
    my ( $self, $package_name ) = @_;

    my $file_name = $self->_get_file_name_for_package_name( $package_name );
    return if not $file_name;

    my @exports = $self->_get_exports_from_file( $file_name );
    return { hashify( @exports ) };
}

#-----------------------------------------------------------------------------

sub _get_exports_from_file {
    my ($self, $file_name) = @_;

    my $doc = PPI::Document->new($file_name);
    if (not $doc) {
        my $pname = policy_short_name(__PACKAGE__);
        die "$pname: could not parse $file_name: $PPI::Document::errstr\n";
    }

    return find_exported_sub_names( $doc );
}

#-----------------------------------------------------------------------------

sub _get_file_name_for_package_name {
    my ($self, $package_name) = @_;

    my $partial_path = $package_name;
    $partial_path =~ s{::}{/}xmsg;
    $partial_path .= '.pm';

    my $full_path = $self->_find_file_in_at_INC( $partial_path );
    return $full_path;
}

#-----------------------------------------------------------------------------

sub _find_file_in_at_INC {
    my ($self, $partial_path) = @_;

    my $inc = $self->_get_inc();
    my $full_path = $inc->find_file( $partial_path );

    if (not $full_path) {
        #TODO reinstate Elliot's error message here.
        my $policy_name = policy_short_name( __PACKAGE__ );
        warn qq{$policy_name: Cannot find source file "$partial_path"\n};
        return;
    }

    return $full_path;
}

#-----------------------------------------------------------------------------

sub _get_qualified_subroutine_calls {
    my ($doc) = @_;

    my $sub_calls_ref = $doc->find( \&_is_subroutine_call );
    return if not $sub_calls_ref;

    my @qualified_sub_calls = grep { $_ =~ m{::}mx } @{$sub_calls_ref};
    return @qualified_sub_calls;
}

#-----------------------------------------------------------------------------

sub _is_subroutine_call {
    my (undef, $elem) = @_;

    if ( $elem->isa('PPI::Token::Word') ) {

        return 0 if is_perl_builtin( $elem );
        return 1 if is_function_call( $elem );

    }
    elsif ($elem->isa('PPI::Token::Symbol')) {

        return 1 if $elem->symbol_type eq q{&};
    }

    return 0;
}



#-----------------------------------------------------------------------------

my %BUILTIN_PACKAGES = hashify( qw(CORE CORE::GLOBAL UNIVERSAL main), $EMPTY );

sub _is_builtin_package {
    my ($package_name) = @_;
    return exists $BUILTIN_PACKAGES{$package_name};
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitCallsToUnexportedSubs

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

Many Perl modules define their public interface by exporting subroutines via
L<Exporter>.  The goal of this Policy is to help enforce encapsulation by
checking that the target of any fully-qualified subroutine call is named
in the module's C<@EXPORT> or C<@EXPORT_OK>.

=head1 LIMITATIONS

This Policy does not properly deal with the L<only> pragma or modules that
don't use L<Exporter> for their export mechanism, such as L<CGI>.

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
