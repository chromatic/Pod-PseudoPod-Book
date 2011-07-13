package Pod::PseudoPod::XHTML;

use strict;
use warnings;

use parent 'Pod::PseudoPod::HTML';

sub end_L
{
    my $self = shift;

    if ($self->{scratch} =~ s/\b(\w+)$//)
    {
        my $link    = $1;
        my $anchors = $self->{_pph_anchors};

        die "Unknown link $link\n" unless exists $anchors->{$link};
        $self->{scratch} .=
            '<a href="'
          . $anchors->{$link}[0]
          . '#' . $link . '">'
          . $anchors->{$link}[1] . "</a>($link)";
    }
}

sub begin_X
{
    my $self = shift;
    $self->emit;
}

sub end_X
{
    my $self    = shift;
    my $scratch = delete $self->{scratch};
    my $anchor  = get_anchor_for_index($self->{file}, $scratch,
        $self->{_pph_entries});

    $self->{scratch} = qq|<div id="$anchor" />|;
    $self->emit;
}

sub start_Document
{
    my ($self) = @_;

    my $xhtml_headers =
        qq{<?xml version="1.0" encoding="UTF-8"?>\n}
      . qq{<!DOCTYPE html\n}
      . qq{     PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"\n}
      . qq{    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">\n} . qq{\n}
      . qq{<html xmlns="http://www.w3.org/1999/xhtml">\n}
      . qq{<head>\n}
      . qq{<title></title>\n}
      . qq{<meta http-equiv="Content-Type" }
      . qq{content="text/html; charset=iso-8859-1"/>\n}
      . qq{<link rel="stylesheet" href="../styles/style.css" }
      . qq{type="text/css"/>\n}
      . qq{</head>\n} . qq{\n}
      . qq{<body>\n};


    $self->{'scratch'} .= $xhtml_headers;
    $self->emit('nowrap');
}

sub start_Z { $_[0]{'scratch'} .= '<div id="' }
sub end_Z   { $_[0]{'scratch'} .= '"/>'; $_[0]->emit() }

sub start_U { $_[0]{'scratch'} .= '<span class="url">' if $_[0]{'css_tags'} }
sub end_U   { $_[0]{'scratch'} .= '</span>' if $_[0]{'css_tags'} }

sub start_N {
  my ($self) = @_;
  $self->{'scratch'} .= '<span class="footnote">' if ($self->{'css_tags'});
  $self->{'scratch'} .= ' (footnote: ';
}

sub end_N {
  my ($self) = @_;
  $self->{'scratch'} .= ')';
  $self->{'scratch'} .= '</span>' if $self->{'css_tags'};
}

sub handle_text { $_[0]{'scratch'} .= encode_entities($_[1]); }

sub end_item_text { $_[0]{'scratch'} .= '</li>'; $_[0]->emit() }

sub start_head0 { $_[0]{'in_head'} = 0 }
sub start_head1 { $_[0]{'in_head'} = 1 }
sub start_head2 { $_[0]{'in_head'} = 2 }
sub start_head3 { $_[0]{'in_head'} = 3 }
sub start_head4 { $_[0]{'in_head'} = 4 }

sub end_head0 { shift->_end_head(@_); }
sub end_head1 { shift->_end_head(@_); }
sub end_head2 { shift->_end_head(@_); }
sub end_head3 { shift->_end_head(@_); }
sub end_head4 { shift->_end_head(@_); }

sub _end_head
{
    my $h = delete $_[0]{in_head};
    $h++;

    my $id   = 'heading_id_' . $_[0]{heading_id}++;
    my $text = $_[0]{scratch};
    $_[0]{'scratch'} = qq{<h$h id="$id">$text</h$h>};
    $_[0]->emit;

    (my $chapter = $_[0]{source_filename}) =~ s/^.*chapter_(\d+).*$/chapter_$1/;

    push @{$_[0]{'to_index'}}, [$h, $id, $text, $chapter];
}

1;
