package Pod::PseudoPod::Book::Command::buildpml;
# ABSTRACT: command module for C<ppbook buildpml>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use Pod::PseudoPod::DOM::App::ToPML;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my ($self, $opt, $args) = @_;
    my @files               = $self->gather_files( 'pml' );

    Pod::PseudoPod::DOM::App::ToPML::process_files_with_output( @files );
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

    return $self->map_chapters_to_output( $suffix, 'pml', @chapters );
}

1;
