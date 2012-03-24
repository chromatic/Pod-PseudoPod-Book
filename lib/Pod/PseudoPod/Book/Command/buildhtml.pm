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
    my $is_epub             = grep { /build_xhtml/ } @$args;
    my $suffix              = $is_epub ? 'xhtml' : 'html';
    my @files               = $self->gather_files( $suffix );

    push @files, '--role=epub' if $is_epub;

    Pod::PseudoPod::DOM::App::ToHTML::process_files_with_output( @files );
}

sub gather_files
{
    my ($self, $suffix) = @_;

    my @chapters;

    if (my @order = $self->chapter_order)
    {
        my $build_prefix  = $self->get_build_prefix;
        @chapters         = map { chomp; catfile( $build_prefix, "$_.pod" ) }
                                @order;
    }
    else
    {
        @chapters = $self->get_built_chapters;
    }

    return $self->map_chapters_to_output( $suffix, 'html', @chapters );
}

1;
