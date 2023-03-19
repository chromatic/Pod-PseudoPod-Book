package Pod::PseudoPod::Book::Command::buildchapters;
# ABSTRACT: command module for C<ppbook buildchapters>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my $self = shift;
    my $conf = $self->config;

    return $self->process_chapters unless $conf->{book}{build_chapters};
    return $self->weave_chapters;
}

sub weave_chapters
{
    my ($self, $opt, $args) = @_;

    my $sections_href = $self->get_section_list;
    die "No sections\n" unless keys %$sections_href;

    for my $chapter ($self->get_chapter_list)
    {
        my $text = process_chapter( $chapter, $sections_href );
        $self->write_chapter( $chapter, $text );
    }

    return unless keys %$sections_href;

    die "Scenes missing from chapters:", join "\n\t", '', keys %$sections_href;
}

sub process_chapters
{
    my ($self, $opt, $args) = @_;
    my $conf                = $self->config;
    my $dir                 = $conf->{layout}{subchapter_directory};
    my $glob_path           = catfile( $dir, '*.pod' );

    for my $chapter ( glob( $glob_path ) )
    {
        my $text = read_file( $chapter );
        $self->write_chapter( $chapter, $text );
    }
}

sub get_chapter_list
{
    my $self      = shift;
    my $conf      = $self->config;
    my $dir       = $conf->{layout}{subchapter_directory};
    my $chapname  = $conf->{layout}{chapter_name_prefix};
    my $glob_path = catfile( $dir, $chapname . '_*.pod' );
    return glob( $glob_path );
}

sub get_section_list
{
    my $self           = shift;
    my $conf           = $self->config;
    my $dir            = $conf->{layout}{subchapter_directory};
    my $chapter_prefix = $conf->{layout}{chapter_name_prefix};
    my $sections_path  = catfile( $dir, '*.pod' );

    my %sections;

    for my $section (glob( $sections_path ))
    {
        next if $section     =~ m!/$chapter_prefix.+\.pod$!;
        my $anchor           =  get_anchor( $section );
        $sections{ $anchor } =  $section;
    }

    return \%sections;
}

sub get_anchor
{
    my $path = shift;

    open my $fh, '<:utf8', $path;

    while (<$fh>)
    {
        next unless /Z<(\w*)>/;
        return $1;
    }

    die "No anchor for file '$path'\n";
}

sub process_chapter
{
    my ($path, $sections_href) = @_;
    my $text                   = read_file( $path );

    $text =~ s/^L<(\w+)>/insert_section( $sections_href, $1, $path )/emg;

    $text =~ s/(=head1 .*)\n\n=head2 \*{3}/$1/g;
    return $text;
}

sub read_file
{
    my $path = shift;
    open my $fh, '<:utf8', $path;

    return scalar do { local $/; <$fh>; };
}

sub insert_section
{
    my ($sections_href, $name, $chapter) = @_;

    die "Unknown section '$name' in '$chapter'\n"
        unless exists $sections_href->{ $1 };

    my $text = read_file( $sections_href->{ $1 } );
    delete $sections_href->{ $1 };
    return $text;
}

sub write_chapter
{
    my ($self, $path, $text) = @_;
    my $conf                 = $self->config;
    my $chapter_build_dir    = $conf->{layout}{chapter_build_directory};
    my $name                 = ( splitpath $path )[-1];
    my $chapter_dir          = catdir( 'build', $chapter_build_dir );
    my $chapter_path         = catfile( $chapter_dir, $name );

    open my $fh, '>:utf8', $chapter_path;

    print {$fh} $text;
}

1;
