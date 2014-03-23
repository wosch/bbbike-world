#!/usr/local/bin/perl
# Copyright (c) June 2012-2013 Wolfram Schneider, http://bbbike.org
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
    "osm.pbf" => "pbf",
    "pbf"     => "pbf",
    "osm.gz"  => "osm.gz",
    "osm"     => "osm.gz",
    "gz"      => "osm.gz",
    "osm.xz"  => "osm.gz",
    "osm.bz2" => "osm.gz",

    "shp.zip" => "shp.zip",
    "shp"     => "shp.zip",

    "obf.zip" => "obf.zip",
    "obf"     => "obf.zip",

    "garmin-cycle.zip"   => "garmin-cycle.zip",
    "garmin-osm.zip"     => "garmin-cycle.zip",
    "garmin-leisure.zip" => "garmin-cycle.zip",
    "garmin-bbbike.zip"  => "garmin-cycle.zip",

    "navit.zip" => "obf.zip",
    "navit"     => "obf.zip",

    "mapsforge-osm.zip" => "mapsforge-osm.zip",

    "o5m.gz"  => "pbf",
    "o5m.bz2" => "pbf",
    "o5m.xz"  => "pbf",

    "csv.xz"  => "pbf",
    "csv.gz"  => "pbf",
    "csv.bz2" => "pbf",

    # needs to be implemented    
    "srtm-europe.osm.pbf" => "pbf",
    "srtm-europe.garmin-osm.zip" => "pbf",
    "srtm-europe.mapsforge-osm.zip" => "pbf",
    "srtm-europe.obf.zip" => "pbf",
    "srtm-southamerica.osm.pbf" => "pbf",

    #"csv.xz"            => "csv.xz",
);

sub Param {
    my $q   = shift;
    my $lat = shift;
    my $sw  = shift;

    # check sw_lat first, then lat_sw parameter
    if ( defined $q->param("${sw}_${lat}") ) {
        return $q->param("${sw}_${lat}");
    }
    else {
        return $q->param("${lat}_${sw}");
    }
}

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

my $lng_sw = Param( $q, "lng", "sw" );
my $lat_sw = Param( $q, "lat", "sw" );
my $lng_ne = Param( $q, "lng", "ne" );
my $lat_ne = Param( $q, "lat", "ne" );

my $factor        = $q->param("factor") || 1;
my $factor_format = 1;
my $format        = $q->param("format") || "";

if ( $format =~ /^([a-zA-Z0-9\-\.]+)$/ ) {
    $format = $1;
}
else {
    $format = "";
}

# find the right database file for a given format
my $ext;
if ( $format && $format{$format} ) {
    $ext = $format{$format};
}
else {
    $ext = $format{"pbf"};
}

my $database_file = "../world/etc/tile/tile-$ext.csv";
my $tile = TileSize->new( 'database' => $database_file );

# guess factor based on similar data
if ( grep { $_ eq $format }
    qw/garmin-leisure.zip garmin-bbbike.zip garmin-osm.zip osm.bz2 osm.xz o5m.bz2 o5m.gz o5m.xz/
  )
{
    if (   exists $tile->{'factor'}->{$format}
        && exists $tile->{'factor'}->{$ext} )
    {
        $factor_format =
          $tile->{'factor'}->{$format} / $tile->{'factor'}->{$ext};
    }
}

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
$size = int( $size * 1000 + 0.5 ) / 1000;

warn
"size: $size, factor $factor, format: $format, ext: $ext, factor_format: $factor_format, ",
  "area: $lng_sw,$lat_sw,$lng_ne,$lat_ne\n"
  if $debug >= 2;

# display JSON result
print qq|{"size": $size }\n|;

1;
