##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.01/lib/Perl/Critic/StricterSubs/Utils.pm $
#     $Date: 2007-04-12 01:12:30 -0700 (Thu, 12 Apr 2007) $
#   $Author: thaljef $
# $Revision: 1464 $
##############################################################################

package Perl::Critic::StricterSubs::Utils;

use strict;
use warnings;

use base 'Exporter';

use Carp qw(croak);

use List::MoreUtils qw( any );
use Perl::Critic::Utils qw(
    &hashify
    &words_from_string
    :characters
    :severities
);

#-----------------------------------------------------------------------------

our $VERSION = 0.01;

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{
    &find_exported_sub_names
    &get_all_subs_from_list_of_symbols
    &get_package_names_from_include_statements
    &get_package_names_from_package_statements
    &parse_literal_list
    &parse_quote_words
    &parse_simple_list
};

#-----------------------------------------------------------------------------

sub parse_simple_list {
    my ($list_node) = @_;
    my $strings_ref = $list_node->find('PPI::Token::Quote');
    return if not $strings_ref;

    my @strings = map { $_->string() } @{ $strings_ref };
    return @strings; #Just hoping that these are single words
}

#-----------------------------------------------------------------------------

sub parse_literal_list {
    my (@nodes) = @_;
    my @string_elems = grep { $_->isa('PPI::Token::Quote') } @nodes;
    return if not @string_elems;

    my @strings = map { $_->string() } @string_elems;
    return @strings;  #Just hoping that these are single words
}

#-----------------------------------------------------------------------------

sub parse_quote_words {
    my ($qw_elem) = @_;
    my ($word_string) = ( $qw_elem =~ m{\A qw. (.*) .\z}msx );
    my @words = words_from_string( $word_string || $EMPTY );
    return @words;
}

#-----------------------------------------------------------------------------

sub get_package_names_from_include_statements {
    my $doc = shift;

    my $statements = $doc->find( \&_wanted_top_level_include_statement );
    return () if not $statements;

    return map { $_->module() } @{$statements};
}

#-----------------------------------------------------------------------------

sub get_package_names_from_package_statements {
    my $doc = shift;

    my $statements = $doc->find( 'PPI::Statement::Package' );
    return () if not $statements;

    return map { $_->namespace() } @{$statements};
}

#-----------------------------------------------------------------------------

sub _wanted_top_level_include_statement {
    my ($doc, $element) = @_;

    return 0 if not $element->isa('PPI::Statement::Include');

    # This will block out file names, e.g. require 'Foo.pm';
    return 0 if not $element->module();

    my $include_type = $element->type();

    # Skip 'no' as in 'no strict'
    return 0 if $include_type ne 'use' && $include_type ne 'require';

    my $parent = $element->parent();

    return 0 if not $parent;
    return 1 if $parent == $doc;
    return 0 if not $parent->isa('PPI::Structure::Block');

    my $grandparent = $parent->parent();

    return 0 if not $grandparent;
    return 0 if not $grandparent->isa('PPI::Statement::Scheduled');

    my $block_type = $grandparent->type();

    return 1
        if
                $block_type eq 'BEGIN'
            ||  $block_type eq 'CHECK'
            ||  $block_type eq 'INIT';

    return 0;
}

#-----------------------------------------------------------------------------

sub _find_exported_names {
    my ($doc) = shift;

    my @export_types = @_ ? @_ : qw{@EXPORT @EXPORT_OK};
    my @all_exports = ();

    for my $export_type( @export_types ) {

        my $export_symbol = _find_export_declaration( $doc, $export_type );
        next if not $export_symbol;

        my @exports = _parse_export_list( $export_symbol );
        foreach (@exports) { s/ \A & //xms; }  # Strip all sub sigils
        push @all_exports, @exports;
    }

    return @all_exports;
}

#-----------------------------------------------------------------------------

sub find_exported_sub_names {
    my ($doc, @export_types) = @_;

    my @exports = _find_exported_names( $doc, @export_types );
    return get_all_subs_from_list_of_symbols( @exports );
}

#-----------------------------------------------------------------------------

sub get_all_subs_from_list_of_symbols {
    my @symbols = @_;

    my @sub_names = grep { m/\A [&\w]/mx } @symbols;
    for (@sub_names) { s/\A &//mx; } # Remove optional sigil

    return @sub_names
}

#-----------------------------------------------------------------------------

sub _find_export_declaration {
    my ($doc, $export_type) = @_;

    my $wanted = _make_symbol_finder( $export_type );
    my $export_symbol = $doc->find( $wanted );
    return if not $export_symbol;

    croak qq{Found multiple $export_type lists. I can't cope}
        if @{$export_symbol} > 1;

    return $export_symbol->[0];
}

#-----------------------------------------------------------------------------

sub _make_symbol_finder {
    my ($wanted_symbol) = @_;

    my $finder = sub {

        my ($doc, $elem) = @_;

        return 0 if not $elem->isa('PPI::Token::Symbol');
        return 0 if $elem ne $wanted_symbol;

        # Check if symbol is on left-hand side of assignment
        my $next_sib = $elem->snext_sibling() || return 0;
        return 0 if not $next_sib->isa('PPI::Token::Operator');
        return 0 if $next_sib ne q{=};

        return 1;
    };

    return $finder;
}

#-----------------------------------------------------------------------------

sub _parse_export_list {
    my ($export_symbol) = @_;

    # First element after the symbol should be "="
    my $snext_sibling  = $export_symbol->snext_sibling();
    return if not $snext_sibling;


    # Gather up remaining elements
    my @left_hand_side = ();
    while ( $snext_sibling = $snext_sibling->snext_sibling() ) {
        push @left_hand_side, $snext_sibling;
    }

    # Did we get any?
    return if not @left_hand_side;


    #Now parse the rest based on type of first element
    my $first_element = $left_hand_side[0];
    return parse_quote_words( $first_element )
        if $first_element->isa('PPI::Token::QuoteLike::Words');

    return parse_simple_list( $first_element )
        if $first_element->isa('PPI::Structure::List');

    return parse_literal_list( @left_hand_side )
        if $first_element->isa('PPI::Token::Quote');


    return; #Don't know what do do!
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords INIT typeglob distro

=head1 NAME

Perl::Critic::StricterSubs::Utils

=head1 AFFILIATION

This module is part of L<Perl::Critic::StricterSubs>.

=head1 DESCRIPTION

This module holds utility methods that are shared by other modules in the
L<Perl::Critic::StricterSubs> distro.  Until this distro becomes more mature,
I would discourage you from using these subs outside of this distro.

=head1 IMPORTABLE SUBS

=over

=item C<parse_quote_words( $qw_elem )>

Gets the words from a L<PPI::Token::Quotelike::Words>.

=item C<parse_simple_list( $list_node )>

Returns the string literals from a L<PPI::Structure::List>.

=item C<parse_literal_list( @nodes )>

Returns the string literals contained anywhere in a collection of
L<PPI::Node>s.

=item C<get_package_names_from_include_statements( $doc )>

Returns a list of module names referred to with a bareword in an
include statement which is directly in the document or a BEGIN, CHECK,
or INIT block.

=item C<get_package_names_from_package_statements( $doc )>

Returns a list of all the namespaces from all the packages statements
that appear in the document.

=item C<find_exported_sub_names( $doc, @export_types )>

Returns a list of subroutines which are exported via the specified export
types.  If C<@export_types> is empty, it defaults to C<qw{ @EXPORT, @EXPORT_OK
}>.

Subroutine names are returned as in
C<get_all_subs_from_list_of_symbols()>.

=item C<get_all_subs_from_list_of_symbols( @symbols )>

Returns a list of all the input symbols which could be subroutine
names.

Subroutine names are considered to be those symbols that don't have
scalar, array, hash, or glob sigils.  Any subroutine sigils are
stripped off; i.e. C<&foo> will be returned as "foo".

=back

=head1 SEE ALSO

L<Exporter>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

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
