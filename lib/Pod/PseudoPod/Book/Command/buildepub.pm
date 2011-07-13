package Pod::PseudoPod::Book::Command::buildepub;
# ABSTRACT: command module for C<ppbook buildepub>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use EBook::EPUB;
use Pod::PseudoPod::XHTML;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my ($self, $opt, $args) = @_;

    my @chapters            = get_chapter_list();
    my $anchors             = get_anchors(@chapters);
    my ($toc, $entries)     = process_chapters($anchors, @chapters);

    generate_index($entries);
    generate_ebook($toc, @chapters);
}

sub get_anchor_for_index
{
    my ($file, $index, $entries) = @_;

    $index =~ s/^(<[pa][^>]*>)+//g;
    $index =~ s/^\s+//g;

    my @paths = split /; /, $index;

    return get_index_entry( $file, $entries, @paths );
}

sub get_index_entry
{
    my ($file, $entries, $name) = splice @_, 0, 3;
    my $key                     = clean_name( $name );
    my $entry                   = $entries->{$key}
                              ||= IndexEntry->new( name => $name );

    if (@_)
    {
        my $subname    = shift;
        my $subkey     = clean_name( $subname );
        my $subentries = $entry->subentries;
        $entry         = $subentries->{$subkey}
                     ||= IndexEntry->new( name => $subname );

        $key .= '__' . $subkey;
    }

    my $locations = $entry->locations;
    (my $anchor   = $key . '_' . @$locations) =~ tr/ //d;

    push @$locations, [ $file, $anchor ];

    return $anchor;
}

sub clean_name
{
    my $name = shift;
    $name    =~ s/<[^>]+>//g;
    $name    =~ tr/ \\/_/;
    $name    =~ s/([^A-Za-z0-9_])/ord($1)/eg;
    return 'i' . $name;
}

sub process_chapters
{
    my ($anchors, @chapters) = @_;

    my @table_of_contents;
    my $entries = {};

    for my $chapter (@chapters)
    {
        my $out_fh              = get_output_fh($chapter);
        my $parser              = Pod::PseudoPod::XHTML->new;
        $parser->{_pph_anchors} = $anchors;
        $parser->{_pph_entries} = $entries;

        $parser->nix_X_codes(0);

        # Set a default heading id for <h?> headings.
        # TODO. Starts at 2 for debugging. Change later.
        $parser->{heading_id} = 2;

        $parser->output_fh($out_fh);

        # output a complete html document
        $parser->add_body_tags(1);

        # add css tags for cleaner display
        $parser->add_css_tags(1);

        $parser->no_errata_section(1);
        $parser->complain_stderr(1);

        my ($file) = $chapter =~ /(chapter_\d+)./;
        $parser->{file} = $file . '.xhtml';

        {
            # P::PP::H uses Text::Wrap which breaks HTML tags
            local *Text::Wrap::wrap;
            *Text::Wrap::wrap = sub { $_[2] };
            $parser->parse_file($chapter);
        }

        push @table_of_contents, @{ $parser->{to_index} };
    }

    return \@table_of_contents;
}

sub get_anchors
{
    my %anchors;

    for my $chapter (@_)
    {
        my ($file)   = $chapter =~ /(chapter_\d+)./;
        my $contents = slurp($chapter);

        while ($contents =~ /^=head\d (.*?)\n\nZ<(.*?)>/mg)
        {
            $anchors{$2} = [$file . '.xhtml', $1];
        }
    }

    return \%anchors;
}

sub slurp
{
    return do { local @ARGV = @_; local $/ = <>; };
}

sub get_chapter_list
{
    my $glob_path = catfile(qw( build chapters chapter_??.pod ));
    return glob $glob_path;
}

sub get_output_fh
{
    my $chapter  = shift;
    my $name     = (splitpath $chapter )[-1];
    my $xhtmldir = catdir(qw( build xhtml ));

    $name =~ s/\.pod/\.xhtml/;
    $name = catfile($xhtmldir, $name);

    open my $fh, '>:utf8', $name;

    return $fh;
}

sub generate_index
{
    my $entries = shift;
    my $fh      = get_output_fh( 'index.pod' );
    my @sorted  = sort { $a cmp $b } keys %$entries;

print $fh <<'END_HEADER';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html
     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Index</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
<link rel="stylesheet" href="../styles/style.css" type="text/css"/>
</head>

<body>
END_HEADER

    print_index( $fh, $entries, \@sorted );

print $fh <<'END_FOOTER';
</body>
</html>
END_FOOTER

}

sub print_index
{
    my ($fh, $entries, $sorted) = @_;

    print $fh "<ul>\n";
    for my $top (@$sorted)
    {
        my $entry = $entries->{$top};

        my $i    = 1;
        my $name = $entry->name;
        my $locs = join ",\n",
            map { my ($f, $l)= @$_; qq|<a href="$f#$l">| . $i++ . '</a>' }
            @{ $entry->locations };

        print $fh "<li>$name\n$locs\n";

        my $subentries = $entry->subentries;
        if (%$subentries)
        {
            my @subkeys = sort { $a cmp $b } keys %$subentries;

            print_index( $fh, $subentries, \@subkeys );
        }
        print $fh "</li>\n";
    }

    print $fh "</ul>\n";
}


##############################################################################
#
# generate_ebook()
#
# Assemble the XHTML pages into an ePub eBook.
#
sub generate_ebook
{
    my ($table_of_contents, @chapters) = @_;

    # Create EPUB object
    my $epub = EBook::EPUB->new;

    # Set the ePub metadata.
    $epub->add_title('Modern Perl');
    $epub->add_author('chromatic');
    $epub->add_language('en');

    # Add the book cover.
    add_cover($epub, './images/mp_cover_full.png');

    # Add some other metadata to the OPF file.
    $epub->add_meta_item('EBook::EPUB version', $EBook::EPUB::VERSION);

    # Add package content: stylesheet, font, xhtml
    $epub->copy_stylesheet('./build/html/style.css', 'styles/style.css');

    for my $chapter (@chapters)
    {
        my $name = (splitpath $chapter )[-1];
        $name =~ s/\.pod/\.xhtml/;
        my $file = "./build/xhtml/$name";

        system( qw( tidy -q -m -utf8 -asxhtml -wrap 0 ), $file );

        $epub->copy_xhtml('./build/xhtml/' . $name,
                          'text/' . $name );
    }

    # Add Pod headings to table of contents.
    set_table_of_contents($epub, $table_of_contents);

    # Generate the ePub eBook.
    my $filename = catfile(qw(build epub modern_perl.epub));
    $epub->pack_zip($filename);
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

    my $play_order = 1;
    my @navpoints  = ($epub) x 5;
    my @navpoint_obj;


    for my $heading (@$pod_headings)
    {

        my $heading_level = $heading->[0];
        my $section       = $heading->[1];
        my $label         = $heading->[2];
        my $content       = 'text/' . $heading->[3] . '.xhtml';


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
    my ($epub, $cover_image) = @_;

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
    <p><img alt="Modern Perl" src="../images/cover.png" /></p>
</body>
</html>

END_XHTML

    # Crete a the cover xhtml file.
    my $cover_filename = './build/xhtml/cover.xhtml';
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

package
    IndexEntry;

sub new
{
    my ($class, %args) = @_;
    bless { locations => [], subentries => {}, %args }, $class;
}

sub name       { $_[0]{name}       }
sub locations  { $_[0]{locations}  }
sub subentries { $_[0]{subentries} }

1;
