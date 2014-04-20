#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use Test::More;
use lib 'world/bin';
use TileSize;

use strict;
use warnings;

# reset default debug value
$TileSize::debug = 0;

plan 'no_plan';

my $tile = new TileSize( 'debug' => -1 );

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

is( $tile->area_size( 0.1,  0.1,  2.9,  2.9,  TileSize::FRACTAL_100 ), 9 );
is( $tile->area_size( -2.9, 0.1,  -0.1, 2.9,  TileSize::FRACTAL_100 ), 9 );
is( $tile->area_size( -2.9, -2.9, -0.1, -0.1, TileSize::FRACTAL_100 ), 9 );
is( $tile->area_size( -1,   -1,   -0,   -0,   TileSize::FRACTAL_100 ), 1 );
is( $tile->area_size( 0,    50,   15,   54,   TileSize::FRACTAL_100 ), 60 );

# dummy
is( $tile->area_size( 0,    0,   0,    0 ),   0 );
is( $tile->area_size( -180, -90, -180, -90 ), 0 );

# count with 50% size of fractal tiles
is( $tile->area_size( 0.1, 0.1,  2.9,  2.9,  TileSize::FRACTAL_50 ), 5 );
is( $tile->area_size( 0,   50,   15,   54,   TileSize::FRACTAL_50 ), 60 );
is( $tile->area_size( 0.5, 50,   15,   54,   TileSize::FRACTAL_50 ), 58 );
is( $tile->area_size( 0.5, 50,   15.5, 54,   TileSize::FRACTAL_50 ), 60 );
is( $tile->area_size( 0.5, 49.5, 15.5, 54,   TileSize::FRACTAL_50 ), 68 );
is( $tile->area_size( 0.5, 49.5, 16.5, 54.1, TileSize::FRACTAL_50 ), 81 );

# count with real size of fractal tiles
is(
    int( $tile->area_size( 0.1, 0.1, 2.9, 2.9, TileSize::FRACTAL_REAL ) * 10 ) /
      10,
    7.8
);
is(
    int( $tile->area_size( 0.8, 0.8, 2.2, 2.2, TileSize::FRACTAL_REAL ) * 10 ) /
      10,
    1.9
);
is( int( $tile->area_size( 1.0, 1.0, 2, 2, TileSize::FRACTAL_REAL ) * 10 ) / 10,
    1 );
is(
    int(
        $tile->area_size( 10.1, 50.1, 12.9, 52.9, TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    7.8
);
is(
    int(
        $tile->area_size( 15.1, 55.1, 17.9, 57.5, TileSize::FRACTAL_REAL ) * 10
      ) / 10,
    6.7
);
is( int( $tile->area_size( 1.1, 1.0, 2, 2, TileSize::FRACTAL_REAL ) * 10 ) / 10,
    0.9 );
is( int( $tile->area_size( 1.5, 1.0, 2, 2, TileSize::FRACTAL_REAL ) * 10 ) / 10,
    0.5 );
is(
    int(
        $tile->area_size( 1.5, 1.5, 2, 2, TileSize::FRACTAL_REAL ) * 100 + 0.5
      ) / 100,
    0.25
);

# date border, Fiji island
cmp_ok( $tile->area_size( 178.9, -18.3, -166.9, -8.4, 2 ), ">", 0 );
cmp_ok(
    $tile->area_size( +172.68, -18.53, -173.12, -8.64, TileSize::FRACTAL_REAL ),
    ">", 100
);
cmp_ok( $tile->area_size( 179.9, -18, +180, +18, TileSize::FRACTAL_100 ),
    "==", 36 );
cmp_ok( $tile->area_size( 179,  0,  180,  1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( 179,  0,  -180, 1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( -180, 0,  -179, 1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( +180, 0,  -179, 1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( +179, -1, -179, 1, TileSize::FRACTAL_100 ), "==", 4 );

# illegal query
cmp_ok( $tile->area_size( +179, 0, +178, 1, TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( -178, 0, -179, 1, TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( -179.5, 0, -179, 1, TileSize::FRACTAL_100 ), "==",
    1 );
cmp_ok( $tile->area_size( +179, 0, +180, 1, TileSize::FRACTAL_100 ), "==", 1 );

cmp_ok( $tile->area_size( -180, 0, -179, 1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( -179, 0, +180, 1, TileSize::FRACTAL_100 ), "==", -1 );

cmp_ok( $tile->area_size( -180, 0, +180, 1, TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( +180, 0, +180, 1, TileSize::FRACTAL_100 ), "==", 0 );

cmp_ok( $tile->area_size( 0, 89,  1, 91,  TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( 0, 91,  1, 92,  TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( 0, -91, 1, -90, TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( 0, -89, 1, -92, TileSize::FRACTAL_100 ), "==", -1 );

cmp_ok( $tile->area_size( -90.1, 0, 81, -89, TileSize::FRACTAL_100 ), "==",
    -1 );
cmp_ok( $tile->area_size( 359, 0, 360, 1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( 359, 0, 361, 1, TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( 369, 0, 391, 1, TileSize::FRACTAL_100 ), "==", -1 );
cmp_ok( $tile->area_size( 512, 512, 512, 512, TileSize::FRACTAL_100 ),
    "==", -1 );
cmp_ok( $tile->area_size( -512, -512, -512, -512, TileSize::FRACTAL_100 ),
    "==", -1 );

# fixable
cmp_ok( $tile->area_size( -280, 0, -279, 1, TileSize::FRACTAL_100 ), "==", 1 );
cmp_ok( $tile->area_size( 280,  0, 281,  1, TileSize::FRACTAL_100 ), "==", 1 );

# test with real planet.osm data
$tile = new TileSize( 'database' => "world/etc/tile/tile-pbf.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 215380 );

$tile = new TileSize( 'database' => "world/etc/tile/tile-garmin-osm.zip.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 226954 );

$tile =
  new TileSize( 'database' => "world/etc/tile/tile-mapsforge-osm.zip.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 172379 );

$tile = new TileSize( 'database' => "world/etc/tile/tile-navit.zip.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 181314 );

$tile = new TileSize( 'database' => "world/etc/tile/tile-obf.zip.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 451733 );

$tile = new TileSize( 'database' => "world/etc/tile/tile-osm.gz.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 424132 );

$tile = new TileSize( 'database' => "world/etc/tile/tile-shp.zip.csv" );
is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 905289 );

# placeholder for osm csv format
#$tile =
#  new TileSize( 'database' => "world/etc/tile/tile-shp.zip.csv" );
#is( int( $tile->area_size( -77.36, 39.92, -70.54, 41.27 ) ), 194908 );

# elevation test
$tile = new TileSize( 'database' => "world/etc/tile/tile-srtm-europe.pbf.csv" );
is(
    int(
        $tile->area_size(
            6.148, 45.955, 11.778, 49.371, TileSize::FRACTAL_REAL
        )
    ),
    82392
);
$tile =
  new TileSize( 'database' => "world/etc/tile/tile-srtm-europe.obf.zip.csv" );
is(
    int(
        $tile->area_size(
            6.148, 45.955, 11.778, 49.371, TileSize::FRACTAL_REAL
        )
    ),
    159617
);

$tile = new TileSize(
    'database' => "world/etc/tile/tile-srtm-europe.garmin-srtm.zip.csv" );
is(
    int(
        $tile->area_size(
            6.148, 45.955, 11.778, 49.371, TileSize::FRACTAL_REAL
        )
    ),
    115754
);

# elevation test
$tile = new TileSize( 'database' => "world/etc/tile/tile-srtm-pbf.csv" );
is(
    int(
        $tile->area_size(
            6.148, 45.955, 11.778, 49.371, TileSize::FRACTAL_REAL
        )
    ),
    65263
);
$tile = new TileSize( 'database' => "world/etc/tile/tile-srtm-obf.zip.csv" );
is(
    int(
        $tile->area_size(
            6.148, 45.955, 11.778, 49.371, TileSize::FRACTAL_REAL
        )
    ),
    216920
);

$tile =
  new TileSize( 'database' => "world/etc/tile/tile-srtm-garmin-srtm.zip.csv" );
is(
    int(
        $tile->area_size(
            6.148, 45.955, 11.778, 49.371, TileSize::FRACTAL_REAL
        )
    ),
    153152
);

__END__
