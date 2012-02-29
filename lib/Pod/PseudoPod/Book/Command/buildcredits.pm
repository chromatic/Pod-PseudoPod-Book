package Pod::PseudoPod::Book::Command::buildcredits;
# ABSTRACT: command module for C<ppbook buildcredits>

use strict;
use warnings;

use parent 'Pod::PseudoPod::Book::Command';

use autodie;
use File::Spec::Functions 'catfile';

sub execute
{
    my ($self, $opt, $args) = @_;
    my $conf                = $self->config;
    return unless $conf->{book}{build_credits};

    my $author_name         = $opt->{author_name}
                           || $conf->{book}{author_name}
                           || '';

    open my $fh, '<:utf8', 'CREDITS';
    my @names;

    while (<$fh>)
    {
        next unless /^N: (.+)$/;
        next if $1 eq $author_name;
        push @names, $1;
    }

    my @sorted = map  { local $" = ' '; "@$_" }
                 sort { $a->[-1] cmp $b->[-1] }
                 map  { [ (split / /, $_) ] }
                 @names;

    my $last = pop @sorted;
    my $dir  = $conf->{layout}{subchapter_directory};

    open my $out_fh, '>:utf8', catfile( $dir, 'credits.pod' );
    print {$out_fh} "Z<credits>\n";

    print {$out_fh} "$_,\n" for @sorted;
    print {$out_fh} "and $last.\n";
}

1;
