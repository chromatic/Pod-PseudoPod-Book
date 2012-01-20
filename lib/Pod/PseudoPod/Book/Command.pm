package Pod::PseudoPod::Book::Command;
# ABSTRACT: base class for all ppbook commands

use strict;
use warnings;

use App::Cmd::Setup -command;
use File::Spec;

sub config
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

sub get_built_chapters
{
    my $self              = shift;
    my $conf              = $self->config;
    my $chapter_prefix    = $conf->{layout}{chapter_name_prefix};
    my $chapter_build_dir = $conf->{layout}{chapter_build_directory};

    return glob File::Spec->catfile(
                    'build', $chapter_build_dir, "${chapter_prefix}_*.pod" );
}

sub get_anchor_list
{
    my ($self, $suffix) = splice @_, 0, 2;
    my $chapter_prefix  = $self->config->{layout}{chapter_name_prefix};
    my %anchors;

    for my $chapter (@_)
    {
        my ($file)   = $chapter =~ /(${chapter_prefix}_\d+)./;
        my $contents = slurp($chapter);

        while ($contents =~ /^=head\d (.*?)\n\nZ<(.*?)>/mg)
        {
            $anchors{$2} = [ $file . $suffix, $1 ];
        }
    }

    return \%anchors;
}

1;
