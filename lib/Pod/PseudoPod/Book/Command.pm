package Pod::PseudoPod::Book::Command;

use strict;
use warnings;

use App::Cmd::Setup -command;

sub opt_spec
{
    my ($class, $app) = @_;
    return $class->options( $app );
}

sub options { [] }

1;
