#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use lib qw(world/bin world/lib);
use BBBikePoly;

use strict;
use warnings;

my $poly = new BBBikePoly( 'debug' => 2 );
my @regions = $poly->list_subplanets;

plan tests => scalar(@regions);

foreach my $region (@regions) {
    my $size    = $poly->subplanet_size($region);
    my $size_mb = $poly->file_size_mb( $size * 1000 );
    cmp_ok( $size, ">", 200_000, "region: $region: $size_mb MB" );
}

__END__
