use strict;
use warnings;

use Open::This;
use Test::More;
use Test::Differences;

{
    my $text        = 'lib/Foo/Bar.pm line 222.';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 222, 'line_number' );
    is( $text, 'lib/Foo/Bar.pm', 'line number stripped' );
}

{
    my $text        = 'lib/Open/This.pm:17';
    my $line_number = Open::This::_maybe_extract_line_number( \$text );
    is( $line_number, 17, 'git-grep line_number' );
    is( $text, 'lib/Open/This.pm', 'git-grep line number stripped' );
}

{
    my $text = 'Open::This::do_something()';
    my $name = Open::This::_maybe_extract_subroutine_name( \$text );
    is( $name, 'do_something', 'subroutine name' );
    is( $text, 'Open::This',   'sub name stripped' );
}

{
    my $text = 'Foo::Bar';
    my $name = Open::This::_maybe_find_local_file($text);
    is( $name, 't/lib/Foo/Bar.pm', 'found local file' );
}

eq_or_diff(
    Open::This::parse_text('t/lib/Foo/Bar.pm line 222.'),
    { file_name => 't/lib/Foo/Bar.pm', line_number => 222, },
    'line 222'
);

eq_or_diff(
    Open::This::parse_text('Foo::Bar::do_something()'),
    {
        file_name   => 't/lib/Foo/Bar.pm',
        line_number => 3,
        sub_name    => 'do_something',
    },
    'line 3'
);

eq_or_diff(
    Open::This::parse_text('t/test-data/foo/bar/baz.html.ep line 5. Blah'),
    {
        file_name   => 't/test-data/foo/bar/baz.html.ep',
        line_number => 5,
    },
    'line 3 in Mojo template'
);

eq_or_diff(
    Open::This::parse_text('t/lib/Foo/Bar.pm:32'),
    {
        file_name   => 't/lib/Foo/Bar.pm',
        line_number => 32,
    },
    'results from git-grep'
);

eq_or_diff(
    Open::This::parse_text('t/Does/Not/Exist'),
    undef,
    'undef on not found file'
);

eq_or_diff(
    Open::This::parse_text('X::Y'),
    undef,
    'undef on not found module'
);

eq_or_diff(
    Open::This::parse_text('t/lib/Foo/Bar.pm'),
    { file_name => 't/lib/Foo/Bar.pm' },
    'file name passed in'
);

eq_or_diff(
    Open::This::parse_text(
        '/Users/olaf/.plenv/versions/5.26.1/lib/perl5/site_perl/5.26.1/String/RewritePrefix.pm line 41.'
    ),
    {
        file_name =>
            '/Users/olaf/.plenv/versions/5.26.1/lib/perl5/site_perl/5.26.1/String/RewritePrefix.pm',
        line_number => 41,
    },
    'line 41 in absolute path'
);

eq_or_diff(
    Open::This::parse_text('/Users/Foo Bar/something/or/other.txt'),
    undef,
    'spaces in file name but not found'
);

eq_or_diff(
    Open::This::parse_text('t/test-data/file with spaces'),
    { file_name => 't/test-data/file with spaces' },
    'spaces in file name and exists'
);

eq_or_diff(
    Open::This::to_editor_args('/Users/Foo Bar/something/or/other.txt'),
    '/Users/Foo Bar/something/or/other.txt',
    'spaces in file name'
);
eq_or_diff(
    [ Open::This::to_editor_args('Foo::Bar::do_something()') ],
    [ '+3', 't/lib/Foo/Bar.pm', ], 'open in vim on line 3'
);

my $more = Open::This::parse_text('Test::More');
ok( $more->{file_name}, 'found Test::More on disk' );

done_testing();
