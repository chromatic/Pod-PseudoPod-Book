package Pod::PseudoPod::Book;
# ABSTRACT: manages books written in the Pod::PseudoPod format

use strict;
use warnings;

use App::Cmd::Setup -app;
use Config::Tiny;

sub config
{
    my $app = shift;
    $app->{config} ||= Config::Tiny->read( 'book.conf' );
}

sub get_command
{
    my $self    = shift;
    my ($cmd, $opt, @args) = $self->SUPER::get_command( @_ );

    unshift @args, 'build_xhtml' if $cmd eq 'buildepub';

    return $cmd, $opt, @args;
}

1;
