#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    my $sub_planet = "../osm/download/sub-planet";

    if ( !-e $sub_planet ) {
        print "1..0 # skip due non-existing directory $sub_planet\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use FindBin;

use Extract::Poly;

use strict;
use warnings;

my $debug = 0;
my $poly  = new Extract::Poly(
    'debug'          => $debug,
    'sub_planet_dir' => "../osm/download/sub-planet"
);
my @regions = $poly->list_subplanets;

plan tests => scalar(@regions) * 2 + 11;

######################################################################################
# list of regions
#

is( scalar(@regions), 14, "14 regions" );

is(
    scalar(@regions),
    scalar( $poly->list_subplanets( 'sort_by' => 'skm' ) ),
    "list of regions"
);

# by default, sub-planets are sorted by sqm
isnt(
    join( "|", @regions ),
    join( "|", $poly->list_subplanets( 'sort_by' => 'disk' ) ),
    "sorted list of regions"
);
isnt(
    join( "|", @regions ),
    join( "|", $poly->list_subplanets( 'sort_by' => 'skm' ) ),
    "sorted list of regions"
);

isnt(
    join( "|", $poly->list_subplanets( 'sort_by' => 'disk' ) ),
    join( "|", $poly->list_subplanets( 'sort_by' => 'skm' ) ),
    "sorted list of regions"
);

{
    my @r = $poly->list_subplanets( 'sort_by' => 'disk' );
    is( shift @r, 'europe-germany-brandenburg',
        "smalles size for europe-germany-brandenburg" );
    is( pop @r, 'europe', "largest size for europe" );
}

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
