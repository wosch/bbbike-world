#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use Data::Dumper;

use lib qw(world/bin world/lib);
use BBBikePoly;

use strict;
use warnings;

my $poly = new BBBikePoly( 'debug' => 1 );
my @regions = $poly->list_subplanets;

plan tests => scalar(@regions) * 2;

foreach my $region (@regions) {
    my $size    = $poly->subplanet_size($region);
    my $size_mb = $poly->file_size_mb( $size * 1000 );
    cmp_ok( $size, ">", 200_000, "region: $region: $size_mb MB" );

    my $obj = $poly->get_job_obj($region);
    my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

    cmp_ok( length($data), ">", 50,
        "poly size: $region: @{[ length($data) ]} bytes" );

    #diag ($data)
}

__END__
