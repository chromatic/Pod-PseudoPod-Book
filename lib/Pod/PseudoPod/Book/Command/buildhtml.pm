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
    my @files               = $self->gather_files( $args );

    Pod::PseudoPod::DOM::App::ToHTML::process_files_with_output(
        @files
    );
}

sub gather_files
{
    my ($self, $args) = @_;
    my %args = map { split /=/, $_, 2 } @$args;

    return $self->map_chapters_to_output unless $args{build_order};

    my $build_prefix  = $self->get_build_prefix;

    return map { chomp; catfile( $build_prefix, $_ ) }
            do { local @ARGV = $args{build_order}; <> };
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
