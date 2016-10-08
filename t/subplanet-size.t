#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

BEGIN {
    my $sub_planet = "../osm/download/sub-planet";

    if ( !-e $sub_planet ) {
        print "1..0 # skip due non-existing directory $sub_planet\n";
        exit;
    }
}

use Test::More;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

use lib qw(world/lib);
use Extract::Poly;

use strict;
use warnings;

my $debug = 1;
my $poly  = new Extract::Poly(
    'debug'          => $debug,
    'sub_planet_dir' => '../osm/download/sub-planet'
);
my @regions = $poly->list_subplanets;

plan tests => scalar(@regions) * 2 + 7;

######################################################################################
# list of regions
#
my @regions2 = $poly->list_subplanets( 'sort_by' => 2 );

is( scalar(@regions), scalar(@regions2), "list of regions" );
cmp_ok( scalar(@regions), ">", 1, "more than one region" );
isnt( join( "|", @regions ), join( "|", @regions2 ), "sorted list of regions" );

foreach my $region (@regions) {
    my $size    = $poly->subplanet_size($region);
    my $size_mb = $poly->file_size_mb( $size * 1000 );
    my $skm =
      $poly->rectangle_km( @{ $Extract::Poly::area->{$region}->{"poly"} } );

    cmp_ok( $size, ">", 200_000, "region: $region: $size_mb MB, $skm skm" );

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
$Extract::Poly::area->{$region}->{"poly"} =
  $Extract::Poly::area->{$region}->{"poly2"};
my $obj = $poly->get_job_obj($region);
my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

is( md5_hex($data), md5_hex($berlin),
    "md5 checksum of poly file Berlin.poly match" );

if ( $debug >= 2 ) {
    diag "Old $berlin";
    diag "New $data";
}

my $size =
  $poly->rectangle_km( @{ $Extract::Poly::area->{$region}->{"poly"} } );
my $size_real = 5452;
is( $size, $size_real, "Area size $region is $size_real" );

#######################################################################################
# check for invalid lng,lat values
#
$region = 'Alien';
$Extract::Poly::area->{$region}->{"poly"} =
  $Extract::Poly::area->{$region}->{"poly2"};
$obj = $poly->get_job_obj($region);
( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

is( $data,    "", "Invalid data, poly file must be empty" );
is( $counter, 0,  "Invalid data, poly counter must be zero" );

__END__
