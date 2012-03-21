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

    Pod::PseudoPod::DOM::App::ToLaTeX::process_files_with_output(
        $self->map_chapters_to_output( 'tex', 'latex',
            $self->get_built_chapters
        )
    );
}

1;
