package Pod::PseudoPod::Book::Command::buildhtml;
# ABSTRACT: command module for C<ppbook buildhtml>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use Pod::PseudoPod::XHTML;
use File::Spec::Functions qw( catfile catdir splitpath );

sub execute
{
    my ($self, $opt, $args) = @_;

    my @chapters = $self->get_built_chapters;
    my $anchors  = $self->get_anchor_list( '.html', @chapters );
    process_chapters( $anchors, @chapters );
}

sub process_chapters
{
    my $anchors = shift;

    for my $chapter (@_)
    {
        my $out_fh              = get_output_fh($chapter);
        my $parser              = Pod::PseudoPod::XHTML->new;
        $parser->{_pph_anchors} = $anchors;

        $parser->output_fh($out_fh);

        # output a complete html document
        $parser->add_body_tags(1);

        # add css tags for cleaner display
        $parser->add_css_tags(1);

        $parser->no_errata_section(1);
        $parser->complain_stderr(1);

        {
            # P::PP::H uses Text::Wrap which breaks HTML tags
            local *Text::Wrap::wrap;
            *Text::Wrap::wrap = sub { $_[2] };
            open my $fh, '<:utf8', $chapter;
            $parser->parse_file($fh);
        }
    }
}

sub slurp
{
    return do { local @ARGV = @_; local $/ = <>; };
}

sub get_output_fh
{
    my $chapter = shift;
    my $name    = ( splitpath $chapter )[-1];
    my $htmldir = catdir( qw( build html ) );

    $name       =~ s/\.pod/\.html/;
    $name       = catfile( $htmldir, $name );

    open my $fh, '>:utf8', $name;

    return $fh;
}

1;
