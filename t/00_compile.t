#!/usr/bin/env perl

use Modern::Perl;
use Test::More;

use lib 'lib';
use Module::Pluggable search_path => [ 'Pod::PseudoPod::Book' ];

for my $module (__PACKAGE__->plugins)
{
    require_ok( $module );
}

done_testing;
