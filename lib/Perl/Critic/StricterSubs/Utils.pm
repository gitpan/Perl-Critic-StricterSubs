##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-StricterSubs-0.02/lib/Perl/Critic/StricterSubs/Utils.pm $
#     $Date: 2007-06-01 01:14:14 -0700 (Fri, 01 Jun 2007) $
#   $Author: thaljef $
# $Revision: 1559 $
##############################################################################

package Perl::Critic::StricterSubs::Utils;

use strict;
use warnings;

use base 'Exporter';

use Carp qw(croak);

use List::MoreUtils qw( any );
use Perl::Critic::Utils qw(
    &first_arg
    &hashify
    &is_function_call
    &is_perl_builtin
    &words_from_string
    :characters
    :severities
);

#-----------------------------------------------------------------------------

our $VERSION = 0.02;

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{
    &find_exported_subroutine_names
    &find_declared_subroutine_names
    &find_declared_constant_names
    &find_imported_subroutine_names
    &find_subroutine_calls
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

    my $statements = $doc->find( \&_wanted_include_statement );
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

sub _wanted_include_statement {
    my ($doc, $element) = @_;

    return 0 if not $element->isa('PPI::Statement::Include');

    # This will block out file names, e.g. require 'Foo.pm';
    return 0 if not $element->module();

    # Skip 'no' as in 'no strict'
    my $include_type = $element->type();
    return 0 if $include_type ne 'use' && $include_type ne 'require';

    return 1;
}

#-----------------------------------------------------------------------------

sub _find_exported_names {
    my ($doc) = shift;

    my @export_types = @_ ? @_ : qw{@EXPORT @EXPORT_OK};
    my @all_exports = ();

    for my $export_type( @export_types ) {

        my $export_assignment = _find_export_assignment( $doc, $export_type );
        next if not $export_assignment;

        my @exports = _parse_export_list( $export_assignment );
        foreach (@exports) { s/ \A & //xms; }  # Strip all sub sigils
        push @all_exports, @exports;
    }

    return @all_exports;
}

#-----------------------------------------------------------------------------

sub find_exported_subroutine_names {
    my ($doc, @export_types) = @_;

    my @exports = _find_exported_names( $doc, @export_types );
    return get_all_subs_from_list_of_symbols( @exports );
}

#-----------------------------------------------------------------------------

sub find_declared_subroutine_names {
    my ($doc) = @_;
    my $sub_nodes = $doc->find('PPI::Statement::Sub');
    return if not $sub_nodes;

    my @sub_names = map { $_->name() } @{ $sub_nodes };
    for (@sub_names) { s{\A .*::}{}mx };  # Remove leading package name
    return @sub_names;
}

#-----------------------------------------------------------------------------

sub find_imported_subroutine_names {
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

sub find_declared_constant_names {
    my ($doc) = @_;

    my $constant_pragmas_ref = $doc->find( \&_is_constant_pragma );
    return if not $constant_pragmas_ref;
    my @declared_constants = ();

    for my $constant_pragma ( @{$constant_pragmas_ref} ) {

        #######################################################
        #  Constant pragmas typically look like one of these:
        # use constant (AVAGADRO => 6.02*10^23);  # With parens
        # use constant  PI => 3.1415927;       # Without parens
        # use constant {FOO => 1, BAR => 1}        # Block form
        #######################################################

        my $pragma_bareword = $constant_pragma->schild(1);
        my $sibling = $pragma_bareword->snext_sibling();

        if ( defined $sibling && $sibling->isa('PPI::Structure::Block') ) {
            # Parse the multi-constant block form...
            push @declared_constants, _get_keys_of_hash($sibling);
        }
        else {
            # Parse the single-constant declaration
            my $constant_name = first_arg( $pragma_bareword ) || next;
            push @declared_constants, $constant_name->content();
        }

    }
    return @declared_constants;
}

#-----------------------------------------------------------------------------

sub _get_keys_of_hash {
    my ($block_or_list_node) = @_;
    return if not defined $block_or_list_node;

    my $fat_commas = $block_or_list_node->find( \&_is_fat_comma )
      or return;

    my @keys = map { $_->sprevious_sibling() } @{$fat_commas};
    return @keys;
}

#-----------------------------------------------------------------------------

sub _is_fat_comma {
    my( undef, $elem) = @_;
    return    $elem->isa('PPI::Token::Operator')
           && $elem eq $FATCOMMA;
}

#-----------------------------------------------------------------------------

sub _is_constant_pragma {
    my (undef, $elem) = @_;

    return    $elem->isa('PPI::Statement::Include')
           && $elem->pragma() eq 'constant'
           && $elem->type() eq 'use';
}

#-----------------------------------------------------------------------------

sub find_subroutine_calls {
    my ($doc) = @_;

    my $sub_calls_ref = $doc->find( \&_is_subroutine_call );
    return if not $sub_calls_ref;
    return @{$sub_calls_ref};
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

    #--------------------------------------------------------------------
    # This handles calls *without* parens, for example:
    # open HANDLE, $path;
    # print HANDLE 'Hello World';
    # close HANDLE;

    if ( my $left_sib = $elem->sprevious_sibling ){
        return exists $functions_that_take_filehandles{ $left_sib }
          && is_function_call( $left_sib );
    }

    #--------------------------------------------------------------------
    # This handles calls *with* parens, for example:
    # open( HANDLE, $path );
    # print( HANDLE 'Hello World' );
    # close( HANDLE );
    #
    # Or this case (Conway-style):
    # print {HANDLE} 'Hello World';

    my $expression = $elem->parent() || return;
    my $enclosing_node = $expression->parent() || return;

    return if ! (    $enclosing_node->isa('PPI::Structure::List')
                  || $enclosing_node->isa('PPI::Structure::Block') );

    return if $enclosing_node->schild(0) != $expression;

    if ( my $left_uncle = $enclosing_node->sprevious_sibling ){
        return exists $functions_that_take_filehandles{ $left_uncle }
          && is_function_call( $left_uncle );
    }

    return;
}

#-----------------------------------------------------------------------------

sub get_all_subs_from_list_of_symbols {
    my @symbols = @_;

    my @sub_names = grep { m/\A [&\w]/mx } @symbols;
    for (@sub_names) { s/\A &//mx; } # Remove optional sigil

    return @sub_names
}

#-----------------------------------------------------------------------------

sub _find_export_assignment {
    my ($doc, $export_type) = @_;

    my $wanted = _make_assignment_finder( $export_type );
    my $export_assignments = $doc->find( $wanted );
    return if not $export_assignments;

    croak qq{Found multiple $export_type lists\n}
        if @{$export_assignments} > 1;

    return $export_assignments->[0];
}

#-----------------------------------------------------------------------------

sub _make_assignment_finder {
    my ($wanted_symbol) = @_;

    #############################################################
    # This function returns a callback functiaon that is suitable
    # for use with the PPI::Node::find() method.  It will find
    # all the occurances of the $wanted_symbol where the symbol
    # is on the immediate left-hand side of the assignment operator.
    ##############################################################

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

=item C<find_declared_subroutine_names( $doc )>

Returns a list of the names for all the subroutines that are declared in the
document.  The package will be stripped from the name.  TODO: Give examples of
what this will return for a given $doc.

=item C<find_declared_constant_names( $doc )>

Returns a list of the names for all the constants that were declared in the
document using the C<constant> pragma.  At the moment, only these styles of
declaration is supported:

  use constant 'FOO' => 42;  #with quotes, no parens
  use constant  BAR  => 27;  #no quotes, no parens
  use constant (BAZ  => 98); #no quotes, with parens

Multiple declarations per pragma are not supported at all:

  use constant {WANGO => 1, TANGO => 2};  #no love here.

=item C<find_imported_subroutine_names( $doc )>

Returns a list of the names of all subroutines that are imported into the
document via C<use MODULE LIST;>.  The leading ampersand sigil will be
stripped.  TODO: Give examples of what this will return for a given $doc.

=item C<find_subroutine_calls( $doc )>

Returns a list C<PPI::Element>s, where each is the bareword name of a static
subroutine invocation.  If the subroutine call is fully-qualified the package
will still be attached to the name.  In all cases, the leading sigil will be
removed.  TODO: Give examples of what this will return for a given $doc.

=item C<find_exported_subroutine_names( $doc )>

Returns a list of the names of each subroutine that is marked for exportation
via C<@EXPORT> or C<@EXPORT_OK>.  Be aware that C<%EXPORT_TAGS> are not
supported here.  TODO: Give examples of what this will return for a given
$doc.

=item C<get_package_names_from_include_statements( $doc )>

Returns a list of module names referred to with a bareword in an
include statement.  This covers all include statements, such as:

  use Foo;
  require Foo;

  sub load_foo {
     require Foo if $condition;
  }

  eval{ require Foo };

  INIT {
     require Foo;
  }

But it does not cover these:

  require "Foo.pm";
  eval { require $foo };

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
