package Pod::PseudoPod::Book::Command;
# ABSTRACT: base class for all ppbook commands

use strict;
use warnings;

use App::Cmd::Setup -command;
use File::Spec;

sub config_file
{
    my ($self, $path) = @_;
    $path           ||= '.';
    my $conf_file     = File::Spec->catfile( $path, 'book.conf' );
    return Config::Tiny->read( $conf_file );
}

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
