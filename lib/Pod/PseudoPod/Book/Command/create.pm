package Pod::PseudoPod::Book::Command::create;
# ABSTRACT: command module for C<ppbook create>

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
    my $conf              = $self->config_file;
    my $dir               = $conf->{layout}{subchapter_directory};

    make_path map { catdir( $book_dir, $_ ) }
                $dir, 'images', map { catdir( 'build', $_ ) }
                                    qw( chapters latex html epub pdf );
}

sub make_conf_file
{
    my ($self, $conf_dir) = @_;
    my $conf_file         = catfile( $conf_dir, 'book.conf' );

    return if Config::Tiny->read( $conf_file );
    my $config = Config::Tiny->new;
    $config->{_}{rootproperty} =
    {
        help => 'See perldoc Pod::PseudoPod::Book::Conf for details',
    };

    $config->{book} =
    {
        title             => '',
        language          => 'en',
        cover_image       => '',
        author_name       => '',
        copyright_year    => (localtime)[5] + 1900,
        filename_template => 'book',
        subtitle          => '',
        build_index       =>  1,
        build_credits     =>  0,
        ISBN10            => '',
        ISBN13            => '',
    };
    $config->{layout} =
    {
        chapter_name_prefix  => 'chapter',
        subchapter_directory => 'sections',
    };

    $config->write( $conf_file );
    print "Please edit '$conf_file' to configure your book\n";
    print "See perldoc Pod::PseudoPod::Book::Conf for details\n";
}

1;
