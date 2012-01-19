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
    my $conf         = $app->config;

    return
    [
        'author_name=s' => "Author's name",
        { default => $conf->{book}{author_name} },

        'copyright_year=s' => 'Copyright year',
        { default => $conf->{book}{copyright_year} },

        'cover_image=s' => 'Path to cover image',
        { default => $conf->{book}{cover_image} },

        'language=s' => 'Language code for contents',
        { default => $conf->{book}{language} },

        'title=s' => 'Book title',
        { default => $conf->{book}{title} },
    ];
}

1;
