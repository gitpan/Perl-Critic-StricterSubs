##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.01/lib/Perl/Critic/Policy/Subroutines/ProhibitCallsToUndeclaredSubs.pm $
#     $Date: 2007-04-12 01:12:30 -0700 (Thu, 12 Apr 2007) $
#   $Author: thaljef $
# $Revision: 1464 $
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs;

use strict;
use warnings;
use base 'Perl::Critic::Policy';

use Perl::Critic::StricterSubs::Utils qw(
    &parse_simple_list
    &parse_literal_list
    &parse_quote_words
    &get_all_subs_from_list_of_symbols
);

use Perl::Critic::Utils qw(
    &hashify
    &first_arg
    &words_from_string
    &is_perl_builtin
    &is_function_call
    :severities
);

#-----------------------------------------------------------------------------

our $VERSION = 0.01;

#-----------------------------------------------------------------------------

sub supported_parameters { return }
sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( strictersubs bugs ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub violates {

    my ($self, undef, $doc) = @_;

    my @declared_sub_names  = _get_declared_subroutine_names( $doc );
    my @imported_sub_names  = _get_imported_subroutine_names( $doc );
    my @declared_constants  = _get_declared_constants( $doc );

    my %defined_sub_names = hashify(@declared_sub_names,
                                    @imported_sub_names,
                                    @declared_constants);

    my @violations = ();
    for my $elem ( _get_unqualified_subroutine_calls($doc) ){
        my ( $name ) = ( $elem =~ m{&?(\w+)}mx );
        if ( not exists $defined_sub_names{$name} ){
            my $expl = q{This might be a major bug};
            my $desc = qq{Subroutine "$elem" is neither declared nor explicitly imported};
            push @violations, $self->violation($desc, $expl, $elem);
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _get_declared_subroutine_names {
    my ($doc) = @_;

    my $subs_ref = $doc->find('PPI::Statement::Sub');
    return if not $subs_ref;

    my @sub_names = map { $_->name() } @{ $subs_ref };
    my @unqualified_sub_names = map { _unqualify_symbol($_) } @sub_names;
    return @unqualified_sub_names;
}

#-----------------------------------------------------------------------------

sub _get_declared_constants {
    my ($doc) = @_;

    my $constant_pragmas_ref = $doc->find( \&_is_constant_pragma );
    return if not $constant_pragmas_ref;

    my @declared_constants = ();
    for my $constant_pragma ( @{$constant_pragmas_ref} ) {

        #######################################################
        #  Constant pragmas typically look like one of these:
        # use constant ( AVAGADRO => 6.02*10^23 ); #With parens
        # use constant PI => 3.1415927;         #Without parens
        #######################################################

        my $pragma_bareword = $constant_pragma->schild(1);
        my $constant_name = first_arg( $pragma_bareword ) || next;
        push @declared_constants, $constant_name->content();
    }

    return @declared_constants;
}

#-----------------------------------------------------------------------------

sub _is_constant_pragma {
    my (undef, $elem) = @_;

    return    $elem->isa('PPI::Statement::Include')
           && $elem->pragma() eq 'constant'
           && $elem->type() eq 'use';
}

#-----------------------------------------------------------------------------

sub _unqualify_symbol {
    my ($symbol) = @_;
    defined $symbol || return;

    $symbol =~ s{ (?: \w*::)* }{}gmx;
    return $symbol;
}

#-----------------------------------------------------------------------------

sub _get_imported_subroutine_names {
    my ($doc) = @_;

    my $includes_ref = $doc->find('PPI::Statement::Include');
    return if not $includes_ref;

    my @use_stmnts = grep { $_->type() eq 'use' }  @{ $includes_ref };

    my @imported_symbols =
        map { _get_imports_from_use_statements($_) } @use_stmnts;

    my @imported_sub_names =
        get_all_subs_from_list_of_symbols( @imported_symbols );

    return @imported_sub_names;
}

#-----------------------------------------------------------------------------

sub _get_imports_from_use_statements {
    my ($use_stmnt) = @_;

    # In a typical C<use> statement, the first child is "use", and the
    # second child is the package name (a bareword).  Everything after
    # that (except the trailing semi-colon) is part of the import
    # arguments.

    my @schildren = $use_stmnt->schildren();
    my @import_args = @schildren[2, -2];

    my $first_import_arg = $import_args[0];
    return if not defined $first_import_arg;

    return parse_quote_words( $first_import_arg )
        if $first_import_arg->isa('PPI::Token::QuoteLike::Words');

    return parse_simple_list( $first_import_arg )
        if $first_import_arg->isa('PPI::Structure::List');

    return parse_literal_list( @import_args )
        if $first_import_arg->isa('PPI::Token::Quote');

    return; #Don't know what to do!

}

#-----------------------------------------------------------------------------

sub _get_unqualified_subroutine_calls {
    my ($doc) = @_;

    my $sub_calls_ref = $doc->find( \&_is_subroutine_call );
    return if not $sub_calls_ref;

    my @unqualified_sub_calls = grep { $_ !~ m{::}mx } @{$sub_calls_ref};
    return @unqualified_sub_calls;
}

#-----------------------------------------------------------------------------

sub _is_subroutine_call {
    my ($doc, $elem) = @_;

    if ( $elem->isa('PPI::Token::Word') ) {

        return 0 if is_perl_builtin( $elem );
        return 0 if _smells_like_filehandle( $elem );
        return 1 if is_function_call( $elem );

    }
    elsif ($elem->isa('PPI::Token::Symbol')) {

        return 1 if $elem->symbol_type eq q{&};
    }

    return 0;
}

#-----------------------------------------------------------------------------

my %functions_that_take_filehandles =
    hashify( qw(print printf read write sysopen tell open close) );

sub _smells_like_filehandle {
    my ($elem) = @_;
    return if not $elem;

    if ( my $left_sib = $elem->sprevious_sibling ){
        return exists $functions_that_take_filehandles{ $left_sib }
            && is_function_call( $left_sib )
    }
}
#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitCallsToUndeclaredSubs

=head1 AFFILIATION

This policy is part of L<Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

This Policy checks that every unqualified subroutine call has a matching
subroutine declaration in the current file, or that it explicitly appears in
the import list for one of the included modules.

=head1 LIMITATIONS

This Policy assumes that the file has no more than one C<package> declaration
and that all subs declared within the file are, in fact, declared into that
same package.  In most cases, violating either of these assumptions means
you're probably doing something that you shouldn't do.  Think twice about what
you're doing.

Also, if you C<require> a module and subsequently call the C<import> method on
that module, this Policy will not detect the symbols that might have been
imported.  In which case, you'll probably get bogus violations.

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
