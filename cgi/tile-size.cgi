#!/usr/local/bin/perl -T
# Copyright (c) June 2012-2017 Wolfram Schneider, https://bbbike.org
#
# tile-size.cgi - compute size of an tile from planet.osm

use CGI;
use CGI::Carp;
use IO::File;
use File::stat;
use lib qw(../world/lib ../lib);
use Extract::TileSize;
use Extract::Config;
use Extract::Planet;

use strict;
use warnings;

$ENV{PATH} = "/bin:/usr/bin";

my $debug = 0;

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

sub sub_planet {
    my $obj = shift;

    my $planet_type_default = 'planet.osm';
    my $format              = $obj->{"format"};
    my $planet_osm          = $Extract::Config::planet_osm;

    # a hash of planet files per format (e.g. OSM, SRTM)
    $planet_osm =
      exists $planet_osm->{$format}
      ? $planet_osm->{$format}
      : $planet_osm->{$planet_type_default};

    if ( !-r "../$planet_osm" ) {
        warn "fatal: cannot find planet.osm file ../$planet_osm, give up!\n";
        return {};
    }

    my $planet = new Extract::Planet( 'debug' => $debug, 'pwd' => '..' );

    my $sub_planet = $planet->get_smallest_planet_file(
        'obj'        => $obj,
        'planet_osm' => $planet_osm
    );

    my $st = $sub_planet ? stat($sub_planet) : undef;

    return {
        "sub_planet_path" => "$sub_planet",
        "sub_planet_size" => $st ? int( $st->size / 1024 ) : 0,
        "planet_osm"      => "$planet_osm",
        "planet_size" => int( $planet->planet_size($planet_osm) / 1024 ) || 0
    };
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

my $area      = $q->param('area');
my $namespace = $q->param('namespace') || $q->param('ns') || '0';

if ( my $d = $q->param('debug') || $q->param('d') ) {
    $debug = $d if defined $d && $d >= 0 && $d <= 3;
}

my $expire = $debug >= 2 ? '+1s' : '+8h';
print $q->header(
    -type                        => 'text/javascript',
    -charset                     => 'utf-8',
    -expires                     => $expire,
    -access_control_allow_origin => '*',
);

my $sw_lng = Param( $q, "lng", "sw" );
my $sw_lat = Param( $q, "lat", "sw" );
my $ne_lng = Param( $q, "lng", "ne" );
my $ne_lat = Param( $q, "lat", "ne" );

my $factor = $q->param("factor") || 1;
my $format = $q->param("format") || "";

if ( $format =~ /^([a-zA-Z0-9\-\.]+)$/ ) {
    $format = $1;
}
else {
    $format = "";
}

# find the right database file for a given format
my $tile_format = $Extract::Config::tile_format;
my $ext;

if ( $format && $tile_format->{$format} ) {
    $ext = $tile_format->{$format};
}
else {
    warn "fall back to PBF tile database\n" if $debug;
    $ext = $tile_format->{"pbf"};
}

my $database_file = "../world/etc/tile/$ext.csv";
my $tile =
  Extract::TileSize->new( 'database' => $database_file, 'debug' => $debug );
my $factor_format = $tile->factor_format( $format, $ext );

# short cut "area=lat,lng,lat,lng"
if ( defined $area ) {
    ( $sw_lng, $sw_lat, $ne_lng, $ne_lat ) = split /,/, $area;
}

if (   !defined $sw_lng
    || !defined $sw_lat
    || !defined $ne_lng
    || !defined $ne_lat )
{
    print "{}\n";
    warn "Missing lat,lng parameter\n";
    exit 0;
}
$factor = 1 if $factor < 0 || $factor > 100;

my $size =
  $factor * $factor_format *
  $tile->area_size( $sw_lng, $sw_lat, $ne_lng, $ne_lat,
    Extract::TileSize::FRACTAL_REAL );
$size = int( $size * 1000 + 0.5 ) / 1000;

my $sub_planet = sub_planet(
    {
        "format" => $format,
        "sw_lng" => $sw_lng,
        "sw_lat" => $sw_lat,
        "ne_lng" => $ne_lng,
        "ne_lat" => $ne_lat
    }
);

# fatal error, give up
if ( !exists $sub_planet->{"planet_size"} ) {
    print "{}\n";
    exit 1;
}

my $sub_planet_path = $sub_planet->{'sub_planet_path'};

# double basename: "sub-srtm/central-europe.osm.pbf"
$sub_planet_path =~ s,.*?/([^/]+/+[^/]+)$,$1,;

warn
"size: $size, param factor $factor, format: $format, ext: $ext, factor_format: $factor_format, ",
  "database_file: $database_file, ",
  "area: $sw_lng,$sw_lat,$ne_lng,$ne_lat",
  ", sub_planet_path: $sub_planet_path", "\n"
  if $debug >= 1;

# display JSON result
print <<EOF;
{
  "size": $size,
  "sub_planet_path": "$sub_planet_path",
  "sub_planet_size": $sub_planet->{'sub_planet_size'},
  "planet_osm": "$sub_planet->{'planet_osm'}",
  "planet_size": $sub_planet->{'planet_size'}
}
EOF

1;
