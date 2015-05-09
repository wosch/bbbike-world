#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

use lib qw(world/bin world/lib);
use BBBikePoly;

use strict;
use warnings;

my $debug   = 1;
my $poly    = new BBBikePoly( 'debug' => $debug );
my @regions = $poly->list_subplanets;

plan tests => scalar(@regions) * 2 + 1;

foreach my $region (@regions) {
    my $size    = $poly->subplanet_size($region);
    my $size_mb = $poly->file_size_mb( $size * 1000 );
    cmp_ok( $size, ">", 200_000, "region: $region: $size_mb MB" );

    my $obj = $poly->get_job_obj($region);
    my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

    cmp_ok( length($data), ">", 50,
        "poly size: $region: @{[ length($data) ]} bytes" );
}

#######################################################################################
# compare the generated poly file with a known good one
#
my $berlin = <<'__EOF__';
Berlin
0
   1.276000E+01  5.223000E+01
   1.398000E+01  5.223000E+01
   1.398000E+01  5.282000E+01
   1.276000E+01  5.282000E+01
   1.276000E+01  5.223000E+01
END
END
__EOF__

my $region = "Berlin";

# activate disabled poly
$BBBikePoly::area->{$region}->{"poly"} =
  $BBBikePoly::area->{$region}->{"poly2"};
my $obj = $poly->get_job_obj($region);
my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

is( md5_hex($data), md5_hex($berlin),
    "md5 checksum of poly file Berlin.poly match" );

if ( $debug >= 2 ) {
    diag "Old $berlin";
    diag "New $data";
}

__END__
