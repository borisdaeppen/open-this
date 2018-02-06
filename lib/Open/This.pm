use strict;
use warnings;
package Open::This;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_text to_editor_args);

use Module::Runtime
    qw( is_module_name module_notional_filename require_module );
use Path::Tiny qw( path );
use Try::Tiny qw( try );

## no critic (Subroutines::ProhibitExplicitReturnUndef)

sub parse_text {
    my $text = shift;

    return undef if !$text;
    my $file_name;
    my $orig;

    my $line_number = _maybe_extract_line_number( \$text );

    # Is this is an actual file.
    $file_name = $text if -e path($text);

    my $sub_name       = _maybe_extract_subroutine_name( \$text );
    my $is_module_name = is_module_name($text);

    if ( !$file_name && $is_module_name ) {
        $file_name = _maybe_find_local_file($text);
    }

    # This is a loadable module.  Have this come after the local module checks
    # so that we don't default to installed modules.
    if ( !$file_name && $is_module_name ) {
        my $found = _module_to_filename($text);
        if ($found) {
            $file_name = $found;
        }
    }

    if ( $file_name && $sub_name ) {
        my $grep = `grep --line-number "sub $sub_name" $file_name`;
        my @results = split m{:}, $grep;
        $line_number = shift @results;
    }

    return $file_name
        ? {
        file_name => $file_name,
        $line_number ? ( line_number => $line_number ) : (),
        $sub_name    ? ( sub_name    => $sub_name )    : (),
        }
        : undef;
}

sub _module_to_filename {
    my $name = shift;
    return undef unless is_module_name($name);
    try { require_module($name) };

    my $notional = module_notional_filename($name);

    return exists $INC{$notional} ? $INC{$notional} : undef;
}

sub to_editor_args {
    my $text = shift;
    return unless $text;

    my $found = parse_text($text);

    # Maybe this file is just being created
    return unless $found;

    return (
        ( $found->{line_number} ? '+' . $found->{line_number} : () ),
        $found->{file_name}
    );
}

sub _maybe_extract_line_number {
    my $text = shift;    # scalar ref

    # Find a line number
    #  lib/Foo/Bar.pm line 222.

    if ( $$text =~ s{ line (\d+).*}{} ) {
        return $1;
    }

    # git-grep (don't match on ::)
    # lib/Open/This.pm:17
    if ( $$text =~ s{(\w):{1}(\d*)\b}{$1} ) {
        return $2;
    }
    return undef;
}

sub _maybe_extract_subroutine_name {
    my $text = shift;    # scalar ref

    if ( $$text =~ s{::(\w+)\(\)}{} ) {
        return $1;
    }
    return undef;
}

sub _maybe_find_local_file {
    my $text          = shift;
    my $possible_name = module_notional_filename($text);
    for my $dir ( 'lib', 't/lib' ) {
        my $path = path( $dir, $possible_name );
        if ( $path->is_file ) {
            return "$path";
        }
    }
    return undef;
}

# ABSTRACT: Try to Do the Right Thing when opening files
1;

=pod

=head1 DESCRIPTION

This module powers the C<ot> command line script, which tries to do the right
thing when opening a file.  Imagine your C<$EDITOR> env var is set to C<vim>.

    ot Foo::Bar # vim lib/Foo/Bar.pm
    ot Foo::Bar # vim t/lib/Foo/Bar.pm

Imagine this module has a sub called do_something at line 55.
    ot "Foo::Bar::do_something()" # vim +55 lib/Foo/Bar.pm

Or, when copy/pasting from a stack trace:
    ot "Foo::Bar line 36" # vim +36 lib/Foo/Bar.pm

Copy/pasting a C<git-grep> result:
    ot "Foo/Bar.pm:99" # vim +99 Foo/Bar.pm

=cut
