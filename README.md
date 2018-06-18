# NAME

Open::This - Try to Do the Right Thing when opening files

[![Build Status](https://travis-ci.org/oalders/open-this.png?branch=master)](https://travis-ci.org/oalders/open-this)

# VERSION

version 0.000008

# DESCRIPTION

This module powers the `ot` command line script, which tries to do the right
thing when opening a file.  Imagine your `$ENV{EDITOR}` is set to `vim`.
(This should also work for `emacs` and `nano`.)  The following examples
demonstrate how your input is translated when launching your editor.

    ot Foo::Bar # vim lib/Foo/Bar.pm
    ot Foo::Bar # vim t/lib/Foo/Bar.pm

Imagine this module has a `sub do_something` at line 55.

    ot "Foo::Bar::do_something()" # vim +55 lib/Foo/Bar.pm

Or, when copy/pasting from a stack trace.  (Note that you do not need quotes in
this case.)

    ot Foo::Bar line 36 # vim +36 lib/Foo/Bar.pm

Copy/pasting a `git-grep` result.

    ot lib/Foo/Bar.pm:99 # vim +99 Foo/Bar.pm

# FUNCTIONS

## parse\_text

Given a scalar value or an array of scalars, this function will try to extract
useful information from it.  Returns a hashref on success.  Returns undef on
failure.  `file_name` is the only hash key which is guaranteed to be in the
hash.

    use Open::This qw( parse_text );
    my $parsed = parse_text('t/lib/Foo/Bar.pm:32');

    # $parsed = { file_name => 't/lib/Foo/Bar.pm', line_number => 32, }

    my $with_sub_name = parse_text( 'Foo::Bar::do_something()' );

    # $with_sub_name = {
    #     file_name   => 't/lib/Foo/Bar.pm',
    #     line_number => 3,
    #     sub_name    => 'do_something',
    # };

## to\_editor\_args

Given a scalar value, this calls `parse_text()` and returns an array of values
which can be passed at the command line to an editor.

    my @args = to_editor_args('Foo::Bar::do_something()');
    # @args = ( '+3', 't/lib/Foo/Bar.pm' );

# ENVIRONMENT VARIABLES

By default, `ot` will search your `lib` and `t/lib` directories for local files.  You can override this via the `$ENV{OPEN_THIS_LIBS}` variable.  It accepts a comma-separated list of libs.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
