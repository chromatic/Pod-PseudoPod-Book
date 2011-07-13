package Pod::PseudoPod::Book::Command::create;

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use File::Path 'make_path';
use File::Spec::Functions qw( catdir catfile );

sub execute
{
    my ($self, $opt, $args) = @_;

    die "No book name given\n" unless @$args == 1;
    my $book_dir = $args->[0];

    $self->make_paths( $book_dir );
    $self->make_conf_file( $book_dir );
}

sub make_paths
{
    my ($self, $book_dir) = @_;

    make_path map { catdir( $book_dir, $_ ) }
                qw( sections images ),
                map { catdir( 'build', $_ ) }
                        qw( chapters latex html epub pdf );
}

sub make_conf_file
{
    my ($self, $conf_dir) = @_;
    my $conf_file         = catfile( $conf_dir, 'book.conf' );

    return if Config::Tiny->read( $conf_file );
    my $config = Config::Tiny->new;
    $config->{book} =
    {
        title          => '',
        language       => 'en',
        cover_image    => '',
        author_name    => '',
        copyright_year => (localtime)[5] + 1900,
    };

    $config->write( $conf_file );
    print "Please edit '$conf_file' to configure your book\n";
}

1;
