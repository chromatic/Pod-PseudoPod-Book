package Pod::PseudoPod::Book::Command::buildlatex;
# ABSTRACT: command module for C<ppbook buildlatex>

use parent 'Pod::PseudoPod::Book::Command';

use strict;
use warnings;

use autodie;
use Path::Class;
use File::Basename;
use Pod::PseudoPod::DOM::App::ToLaTeX;

sub execute
{
    my ($self, $opt, $args) = @_;
    my $output_dir          = dir( qw( build latex ) );

    my %files = map
    {
        my $file     = $_;
        my $filename = fileparse( $file, qr{\..*} ) . '.pod';
        (my $texname = $filename) =~ s/\.pod$/\.tex/;
        my $outfile  = file( $output_dir, $texname );

        $file => $outfile,
    } get_chapter_list();

    Pod::PseudoPod::DOM::App::ToLaTeX::process_files_with_output( %files );
}

sub get_chapter_list
{
    my $glob_path = file( qw( build chapters chapter_??.pod ) );
    return glob "$glob_path";
}

1;
