use strict;
use warnings;
package Open::This;

use feature qw( say );
use Path::Tiny qw( path );

sub to_file {
    my $text = shift;

    if ( $text =~ m{::} ) {
        my @parts = split m{::}, $text;
        my $sub_name;
        if ( $parts[-1] =~ m{\(} ) {
            $sub_name = pop @parts;
            $sub_name =~ s{[\(\)]}{}g;
        }
        $parts[-1] = $parts[-1] . '.pm';
        my $file_name;
        my $line_number;

        for my $dir ( 'lib', 't/lib' ) {
            my $path = path( $dir, @parts );
            if ( -e $path ) {
                $file_name = "$path";
                last;
            }
        }

        if ( $file_name && $sub_name ) {
            my $grep = `grep --line-number "sub $sub_name" $file_name`;
            my @results = split m{:}, $grep;
            $line_number = shift @results;
        }

        return {
            file_name   => $file_name,
            line_number => $line_number,
            $sub_name ? ( sub_name => $sub_name ) : (),
        };
    }

    #at lib/Foo/Bar.pm line 222.
    if ( $text =~ m{\b([^\s]*) line (\d*)} ) {
        return { file_name => $1, line_number => $2 };
    }

    # git-grep
    if ( $text =~ m{\b([^\s]*):(\d*):} ) {
        return { file_name => $1, line_number => $2 };
    }
    return undef;
}

sub to_vim {
    my $text    = shift;
    my $found   = to_file($text);
    my @command = (
        'vim',
        ( $found->{line_number} ? '+' . $found->{line_number} : () ),
        $found->{file_name}
    );
    return join q{ }, @command;
}

1;
