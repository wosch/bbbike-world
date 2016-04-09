#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use lib qw(world/lib);
use Extract::TileSize;

use strict;
use warnings;

# reset default debug value
$Extract::TileSize::debug     = 0;
$Extract::TileSize::use_cache = 0;

plan tests => 113;

my $tile = new Extract::TileSize( 'debug' => -1 );

ok(1);

is( $tile->total, 64800 );

# count with 100% size of fractal tiles
is( $tile->area_size( 0,    0,    1,    1 ),   1 );
is( $tile->area_size( 0.2,  0.2,  1,    1 ),   1 );
is( $tile->area_size( 0.2,  0.2,  0.8,  0.8 ), 1 );
is( $tile->area_size( -180, -90,  -179, -89 ), 1 );
is( $tile->area_size( 0,    0,    2,    2 ),   4 );
is( $tile->area_size( -2,   -2,   0,    0 ),   4 );
is( $tile->area_size( -1,   -1,   1,    1 ),   4 );
is( $tile->area_size( -1.5, -1.5, 1.5,  1.5 ), 16 );
is( $tile->area_size( -1.5, -1.5, 1,    1 ),   9 );
is( $tile->area_size( 0,    50,   15,   54 ),  60 );
is( $tile->area_size( 0.1,  0,    3,    3 ),   9 );
is( $tile->area_size( 0.1,  0.1,  2.9,  2.9 ), 9 );

is( $tile->area_size( 0.1, 0.1, 2.9, 2.9, Extract::TileSize::FRACTAL_100 ), 9 );
is( $tile->area_size( -2.9, 0.1, -0.1, 2.9, Extract::TileSize::FRACTAL_100 ),
    9 );
is( $tile->area_size( -2.9, -2.9, -0.1, -0.1, Extract::TileSize::FRACTAL_100 ),
    9 );
is( $tile->area_size( -1, -1, -0, -0, Extract::TileSize::FRACTAL_100 ), 1 );
is( $tile->area_size( 0,  50, 15, 54, Extract::TileSize::FRACTAL_100 ), 60 );

# dummy
is( $tile->area_size( 0,    0,   0,    0 ),   0 );
is( $tile->area_size( -180, -90, -180, -90 ), 0 );

# count with 50% size of fractal tiles
is( $tile->area_size( 0.1, 0.1, 2.9, 2.9, Extract::TileSize::FRACTAL_50 ), 5 );
is( $tile->area_size( 0,   50,  15,  54,  Extract::TileSize::FRACTAL_50 ), 60 );
is( $tile->area_size( 0.5, 50,  15,  54,  Extract::TileSize::FRACTAL_50 ), 58 );
is( $tile->area_size( 0.5, 50, 15.5, 54, Extract::TileSize::FRACTAL_50 ), 60 );
is( $tile->area_size( 0.5, 49.5, 15.5, 54, Extract::TileSize::FRACTAL_50 ),
    68 );
is( $tile->area_size( 0.5, 49.5, 16.5, 54.1, Extract::TileSize::FRACTAL_50 ),
    81 );

# count with real size of fractal tiles
is(
    int(
        $tile->area_size( 0.1, 0.1, 2.9, 2.9, Extract::TileSize::FRACTAL_REAL )
          * 10
      ) / 10,
    7.8
);
is(
    int(
        $tile->area_size( 0.8, 0.8, 2.2, 2.2, Extract::TileSize::FRACTAL_REAL )
          * 10
      ) / 10,
    1.9
);
is(
    int(
        $tile->area_size( 1.0, 1.0, 2, 2, Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    1
);
is(
    int(
        $tile->area_size( 10.1, 50.1, 12.9, 52.9,
            Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    7.8
);
is(
    int(
        $tile->area_size( 15.1, 55.1, 17.9, 57.5,
            Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    6.7
);
is(
    int(
        $tile->area_size( 1.1, 1.0, 2, 2, Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    0.9
);
is(
    int(
        $tile->area_size( 1.5, 1.0, 2, 2, Extract::TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    0.5
);
is(
    int(
        $tile->area_size( 1.5, 1.5, 2, 2, Extract::TileSize::FRACTAL_REAL ) *
          100 + 0.5
      ) / 100,
    0.25
);

# date border, Fiji island
cmp_ok( $tile->area_size( 178.9, -18.3, -166.9, -8.4, 2 ), ">", 0 );
cmp_ok(
    $tile->area_size(
        +172.68, -18.53, -173.12, -8.64, Extract::TileSize::FRACTAL_REAL
    ),
    ">", 100
);
cmp_ok(
    $tile->area_size( 179.9, -18, +180, +18, Extract::TileSize::FRACTAL_100 ),
    "==", 36 );
cmp_ok( $tile->area_size( 179, 0, 180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( 179, 0, -180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( -180, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( +180, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( +179, -1, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 4 );

# illegal query
cmp_ok( $tile->area_size( +179, 0, +178, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( -178, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( -179.5, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( +179, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );

cmp_ok( $tile->area_size( -180, 0, -179, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( -179, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );

cmp_ok( $tile->area_size( -180, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( +180, 0, +180, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 0 );

cmp_ok( $tile->area_size( 0, 89, 1, 91, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 0, 91, 1, 92, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 0, -91, 1, -90, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 0, -89, 1, -92, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );

cmp_ok( $tile->area_size( -90.1, 0, 81, -89, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 359, 0, 360, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( 359, 0, 361, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 369, 0, 391, 1, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( 512, 512, 512, 512, Extract::TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok(
    $tile->area_size( -512, -512, -512, -512, Extract::TileSize::FRACTAL_100 ),
    "==", -1
);

# fixable
cmp_ok( $tile->area_size( -280, 0, -279, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );
cmp_ok( $tile->area_size( 280, 0, 281, 1, Extract::TileSize::FRACTAL_100 ),
    "==", 1 );

# test with real planet.osm data
$tile = new Extract::TileSize( 'database' => "world/etc/tile/pbf.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 52712 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 276916 );
is( $tile->total_tiles, 15218 );
is( $tile->total,       21533280 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/garmin-osm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 37242 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 237122 );
is( $tile->total_tiles, 13575 );
is( $tile->total,       17488294 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/garmin-onroad.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 3919 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 70386 );
is( $tile->total_tiles, 6986 );
is( $tile->total,       4229583 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/mapsforge-osm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 48110 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 242541 );
is( $tile->total_tiles, 15218 );
is( $tile->total,       21515672 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/navit.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 49332 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 257793 );
is( $tile->total_tiles, 14301 );
is( $tile->total,       19082126 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/obf.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 139044 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 596378 );
is( $tile->total_tiles, 15218 );
is( $tile->total,       38775514 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/osm.gz.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 101734 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 534450 );
is( $tile->total_tiles, 15218 );
is( $tile->total,       41559400 );

$tile = new Extract::TileSize( 'database' => "world/etc/tile/shp.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 265234 );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 1319708 );
is( $tile->total_tiles, 15213 );
is( $tile->total,       95238835 );

# placeholder for osm csv format
#$tile =
#  new Extract::TileSize( 'database' => "world/etc/tile/shp.zip.csv" );
#is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 194908 );

my $size = Extract::TileSize::FRACTAL_REAL;

# elevation test
$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/srtm-europe-pbf.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 396 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 82392 );
$tile = new Extract::TileSize(
    'database' => "world/etc/tile/srtm-europe-obf.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 554 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 159617 );

$tile = new Extract::TileSize(
    'database' => "world/etc/tile/srtm-europe-garmin-srtm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 515 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 115754 );

####################################################################
# elevation test with planet-srtm.pbf
#
$tile = new Extract::TileSize( 'database' => "world/etc/tile/srtm-pbf.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 244 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 65263 );
is( $tile->total_tiles, 13418 );
is( $tile->total,       14387080 );

$tile =
  new Extract::TileSize( 'database' => "world/etc/tile/srtm-obf.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 342 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 216920 );
is( $tile->total_tiles, 13418 );
is( $tile->total,       39058946 );

$tile = new Extract::TileSize(
    'database' => "world/etc/tile/srtm-garmin-srtm.zip.csv" );
is( int( $tile->area_size(qw/13 52 14 53/) ), 317 );
is( int( $tile->area_size( 6.148, 45.955, 11.778, 49.371, $size ) ), 153152 );
is( $tile->total_tiles, 13418 );
is( $tile->total,       28491956 );

__END__
