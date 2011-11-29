package Pod::PseudoPod::Book::Command::buildpdf;
# ABSTRACT: command module for C<ppbook buildpdf>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';
use Path::Class;
use File::chdir;

sub execute
{
    my ($self, $opt, $args) = @_;
    my %sizes               = map { $_ => 1 } qw( letter a4 6x9 );
    my $conf                = $self->config_file;
    my $size                = 'letter';
    my $latex_dir           = dir(qw( build latex ));
    my $filename_template   = $conf->{book}{filename_template};

    for my $arg (@$args)
    {
        next unless exists $sizes{$arg};
        $size = $arg;
    }

    push @CWD, "$latex_dir";
    my $tex_file = $filename_template . '_' . $size . '.tex';
    my $idx_file = $filename_template . '_' . $size . '.idx';
    unlink $idx_file;

    die "No LaTeX file found at '$tex_file'\n" unless -e $tex_file;
    die "pdflatex failed for $tex_file: $!"  if system 'pdflatex',  $tex_file;

    return unless $conf->{book}{build_index};

    die "makeindex failed for $idx_file: $!" if system 'makeindex', $idx_file;
    die "pdflatex failed for $tex_file: $!"  if system 'pdflatex',  $tex_file;

    pop @CWD;
}

1;
