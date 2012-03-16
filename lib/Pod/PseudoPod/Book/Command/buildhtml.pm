package Pod::PseudoPod::Book::Command::buildhtml;
# ABSTRACT: command module for C<ppbook buildhtml>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use Pod::PseudoPod::DOM::App::ToHTML;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my ($self, $opt, $args) = @_;

    Pod::PseudoPod::DOM::App::ToHTML::process_files_with_output(
        $self->map_chapters_to_output
    );
}

sub map_chapters_to_output
{
    my $self      = shift;
    my $build_dir = $self->config->{layout}{chapter_build_directory};

    return map
    {
        my $dest = $_;
        $dest =~ s!/$build_dir/!/html/!;
        [ $_ => $_ ];
    } $self->get_built_chapters;
}

1;
