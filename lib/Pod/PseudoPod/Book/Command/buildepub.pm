package Pod::PseudoPod::Book::Command::buildepub;
# ABSTRACT: command module for C<ppbook buildepub>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use EBook::EPUB;
use File::Slurp;
use File::Basename;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my ($self, $opt, $args) = @_;
    my $conf                = $self->config;
    my @chapters            = $self->get_built_html( 'xhtml' );
    my $toc                 = $self->get_toc( @chapters );

    generate_ebook( $conf, $toc, @chapters );
}

sub get_toc
{
    my $self = shift;
    my @toc;

    for my $chapter (@_)
    {
        my $contents = File::Slurp::read_file( $chapter );
        while ($contents =~ /<h(\d) id="([^"]+)">(.+)<\/h\1>/g)
        {
            my ($level, $identifier, $label) = ($1, $2, $3);
            $label =~ s/<[^>]+>//g;
            $label =~ s/&amp;/&/g;
            push @toc, [ $level, $identifier, $label, $chapter ];
        }
    }

    return \@toc;
}

##############################################################################
#
# generate_ebook()
#
# Assemble the XHTML pages into an ePub eBook.
#
sub generate_ebook
{
    my ($conf, $table_of_contents, @chapters) = @_;

    # Create EPUB object
    my $epub     = EBook::EPUB->new;
    my $metadata = $conf->{book};

    # Set the ePub metadata.
    $epub->add_title(      $metadata->{title}       );
    $epub->add_author(     $metadata->{author_name} );
    $epub->add_language(   $metadata->{language}    );
    $epub->add_publisher(  $metadata->{publisher}   ) if $metadata->{publisher};

    $epub->add_identifier( $metadata->{ISBN13}, 'ISBN' )
        if $metadata->{ISBN13};

    # Add the book cover.
    my $cover = $conf->{book}{cover_image};
    add_cover($conf, $epub, $cover) if -e $cover;

    # Add some other metadata to the OPF file.
    $epub->add_meta_item('EBook::EPUB version', $EBook::EPUB::VERSION);

    # Add package content: stylesheet, font, html
    $epub->copy_stylesheet('./build/html/style.css', 'styles/style.css');

    add_chapters( $epub, @chapters );
    add_images( $epub );

    # Add Pod headings to table of contents.
    set_table_of_contents($epub, $table_of_contents);
    (my $filename_title = lc $conf->{book}{title} . '.epub') =~ s/\s+/_/g;

    # Generate the ePub eBook.
    my $filename = catfile( qw( build epub ), $filename_title );
    $epub->pack_zip($filename);
}

sub add_images
{
    my $epub       = shift;
    my %mime_types =
    (
        jpg => 'image/jpeg',
        gif => 'image/gif',
        png => 'image/png',
    );

    for my $image (glob( './build/images/*' ))
    {
        my ($name, $path, $suffix) = fileparse( $image, qw( jpg gif png ) );
        my $mime_type              = $mime_types{$suffix};
        my $dest                   = "text/images/$name$suffix";

        die "Unknown image '$image'" unless $mime_type;
        $epub->add_image_entry( $image, $mime_type );
        $epub->copy_file( $image, $dest, $mime_type );
    }
}

sub add_chapters
{
    my $epub = shift;

    for my $chapter (@_)
    {
        my $file = (splitpath $chapter )[-1];
        (my $dest = $file) =~ s/\.html/\.xhtml/;

        $epub->copy_xhtml( $chapter, 'text/' . $dest );
    }
}


##############################################################################
#
# set_table_of_contents()
#
# Add the Pod headings to the NCX <navMap> table of contents.
#
sub set_table_of_contents
{
    my $epub         = shift;
    my $pod_headings = shift;

    my $play_order   = 1;
    my @navpoints    = ($epub) x 5;
    my @navpoint_obj;

    for my $heading (@$pod_headings)
    {
        my $heading_level = $heading->[0];
        my $section       = $heading->[1];
        my $label         = $heading->[2];
        (my $filename     = $heading->[3]) =~ s!.*/([^/]+).html$!$1.xhtml!;
        my $content       = 'text/' . $filename;

        # Add the pod section to the NCX data, Except for the root heading.
        $content .= '#' . $section if $section ne 'heading_id_2';

        my %options = (
                       content    => $content,
                       id         => 'navPoint-' . $play_order,
                       play_order => $play_order,
                       label      => $label,
                      );

        $play_order++;

        # Add the navpoints at the correct nested level.
        my $navpoint_obj = $navpoints[$heading_level - 1];

        $navpoint_obj = $navpoint_obj->add_navpoint(%options);

        # The returned navpoint object is used for the next nested level.
        $navpoints[$heading_level] = $navpoint_obj;

        # This is a workaround for non-contiguous heading levels.
        $navpoints[$heading_level + 1] = $navpoint_obj;
    }
}


###############################################################################
#
# add_cover()
#
# Add a cover image to the eBook. Add cover metadata for iBooks and add an
# additional cover page for other eBook readers.
#
sub add_cover
{
    my ($conf, $epub, $cover_image) = @_;

    # Check if the cover image exists.
    if (!-e $cover_image)
    {
        warn "Cover image $cover_image not found.\n";
        return;
    }

    # Add cover metadata for iBooks.
    my $cover_id = $epub->copy_image($cover_image, 'images/cover.png');
    $epub->add_meta_item('cover', $cover_id);

    # Add an additional cover page for other eBook readers.
    my $cover_xhtml = <<END_XHTML;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="Content-Type" ]
content="text/html; charset=iso-8859-1"/>
<style type="text/css"> img { max-width: 100%; }</style>
</head>
<body>
    <p><img alt="$conf->{book}{title}" src="../images/cover.png" /></p>
</body>
</html>

END_XHTML

    # Create the cover xhtml file.
    my $cover_filename = './build/html/cover.xhtml';
    open my $cover_fh, '>:utf8', $cover_filename;

    print $cover_fh $cover_xhtml;
    close $cover_fh;

    # Add the cover page to the ePub doc.
    $epub->copy_xhtml($cover_filename, 'text/cover.xhtml' );

    # Add the cover to the OPF guide.
    my $guide_options =
    {
        type  => 'cover',
        href  => 'text/cover.xhtml',
        title => 'Cover',
    };

    $epub->guide->add_reference($guide_options);

    return $cover_id;
}

1;
