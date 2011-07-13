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

1;
