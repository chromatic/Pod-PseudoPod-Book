#! perl

use Test::More;
use strict;
use warnings;

use_ok 'Pod::PseudoPod::Book'
    or exit;

my $ppb = Pod::PseudoPod::Book->new;
isa_ok $ppb, 'Pod::PseudoPod::Book';

done_testing();
