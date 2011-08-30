#! perl

use Test::More;
use strict;
use warnings;

use_ok 'Pod::PseudoPod::Book'
    or exit;

my $app = Pod::PseudoPod::Book->new;
isa_ok $app, 'Pod::PseudoPod::Book';

done_testing();
