#!/usr/local/bin/perl
# Copyright (c) June 2012 Wolfram Schneider, http://bbbike.org
#
# tile-size.cgi - compute size of an tile from planet.osm

use CGI;
use CGI::Carp;
use IO::File;
use lib '../world/bin';
use lib '../bin';
use TileSize;

use strict;
use warnings;

my $debug = 2;

# $TileSize::debug = 2;

# map format to database
my %format = (
    "osm.pbf"            => "pbf",
    "pbf"                => "pbf",
    "osm.gz"             => "osm.gz",
    "osm"                => "osm.gz",
    "gz"                 => "osm.gz",
    "osm.xz"             => "osm.gz",
    "osm.bz2"            => "osm.gz",
    "shp.zip"            => "shp.zip",
    "shp"                => "shp.zip",
    "obf.zip"            => "obf.zip",
    "obf"                => "obf.zip",
    "garmin-cycle.zip"   => "garmin-cycle.zip",
    "garmin-osm.zip"     => "garmin-cycle.zip",
    "garmin-leisure.zip" => "garmin-cycle.zip",
    "navit.zip"          => "obf.zip",
    "navit"              => "obf.zip",
    "o5m.gz"             => "pbf",
    "o5m.bz2"            => "pbf",
);

######################################################################
# GET /w/api.php?namespace=1&q=berlin HTTP/1.1
#
# param alias: q: query, search
#              ns: namespace
#

binmode( \*STDERR, ":raw" );
binmode( \*STDOUT, ":raw" );

my $q = new CGI;

my $area = $q->param('area');
my $namespace = $q->param('namespace') || $q->param('ns') || '0';

if ( my $d = $q->param('debug') || $q->param('d') ) {
    $debug = $d if defined $d && $d >= 0 && $d <= 3;
}

my $expire = $debug >= 2 ? '+1s' : '+1h';
print $q->header(
    -type                        => 'text/javascript',
    -charset                     => 'utf-8',
    -expires                     => $expire,
    -access_control_allow_origin => '*',
);

my $lng_sw        = $q->param("lng_sw");
my $lat_sw        = $q->param("lat_sw");
my $lng_ne        = $q->param("lng_ne");
my $lat_ne        = $q->param("lat_ne");
my $factor        = $q->param("factor") || 1;
my $factor_format = 1;
my $format        = $q->param("format") || "";

my $ext;
if ( $format && $format{$format} ) {
    $ext = $format{$format};

    # guess factor based on similar data
    $factor_format *= 1.3  if $format eq 'garmin-leisure.zip';
    $factor_format *= 0.65 if $format eq 'navit.zip';

    $factor_format *= 0.7  if $format eq 'osm.bz2';
    $factor_format *= 0.75 if $format eq 'osm.xz';

    $factor_format *= 0.88 if $format eq 'o5m.bz2';
    $factor_format *= 1.04 if $format eq 'o5m.gz';
}
else {
    $ext = $format{"pbf"};
}

my $database_file = "../world/etc/tile/tile-$ext.csv";
my $tile = TileSize->new( 'database' => $database_file );

# short cut "area=lat,lng,lat,lng"
if ( defined $area ) {
    ( $lng_sw, $lat_sw, $lng_ne, $lat_ne ) = split /,/, $area;
}

if (   !defined $lng_sw
    || !defined $lat_sw
    || !defined $lng_ne
    || !defined $lat_ne )
{
    print "{}\n";
    warn "Missing lat,lng parameter\n";
    exit 0;
}
$factor = 1 if $factor < 0 || $factor > 100;

my $size =
  $factor *
  $factor_format *
  $tile->area_size( $lng_sw, $lat_sw, $lng_ne, $lat_ne,
    TileSize::FRACTAL_REAL );
$size = int( $size * 10 + 0.5 ) / 10;

warn "size: $size, factor $factor, format: $format, ",
  "area: $lng_sw,$lat_sw,$lng_ne,$lat_ne\n"
  if $debug >= 2;

# display JSON result
print qq|{"size": $size }\n|;

1;
