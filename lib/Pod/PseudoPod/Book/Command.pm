package Pod::PseudoPod::Book::Command;

use strict;
use warnings;

use App::Cmd::Setup -command;

sub opt_spec
{
    my ($class, $app) = @_;
    return $class->options( $app );
}

sub options
{
    my ($self, $app) = @_;

    return
    [
        'author_name=s' => "Author's name",
        { default => $app->config->{book}{author_name} },

        'copyright_year=s' => 'Copyright year',
        { default => $app->config->{book}{copyright_year} },

        'cover_image=s' => 'Path to cover image',
        { default => $app->config->{book}{cover_image} },

        'language=s' => 'Language code for contents',
        { default => $app->config->{book}{language} },

        'title=s' => 'Book title',
        { default => $app->config->{book}{title} },
    ];
}

1;
