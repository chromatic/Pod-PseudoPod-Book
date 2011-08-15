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
    my $author_name         = $opt->{author_name} || '';

    open my $fh, '<:utf8', 'CREDITS';
    my @names;

    while (<$fh>)
    {
        next unless /^N: (.+)$/;
        next if $1 eq $author_name;
        push @names, $1;
    }

    open my $out_fh, '>:utf8', catfile(qw( sections credits.pod ));
    print {$out_fh} "Z<credits>\n";

    print {$out_fh} "$_,\n"
        for map  { local $" = ' '; "@$_" }
            sort { $a->[-1] cmp $b->[-1] }
            map  { [ (split / /, $_) ] }
            @names;

}

1;
