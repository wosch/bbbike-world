#!/usr/local/bin/perl -T
# Copyright (c) June 2012-2014 Wolfram Schneider, http://bbbike.org
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

my $debug = 2;

# $Extract::TileSize::debug = 2;

# map format to database

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

    my $planet_osm = $Extract::Planet::config->{'planet_osm'};
    my $planet = new Extract::Planet( 'debug' => $debug, 'pwd' => '..' );

    my $sub_planet = $planet->get_smallest_planet_file(
        'obj'        => $obj,
        'planet_osm' => $planet_osm
    );

    my $st = $sub_planet ? stat($sub_planet) : undef;

    if ( $sub_planet && $st ) {
        return {
            "sub_planet_path" => $sub_planet,
            "sub_planet_size" => int( $st->size / 1024 ),
            "planet_osm"      => $planet_osm,
            "planet_size"     => int( $planet->planet_size($planet_osm) / 1024 )
        };
    }
    else {
        return {};
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
my $tile_format = $Extract::Config::tile_format;
my $ext;

if ( $format && $tile_format->{$format} ) {
    $ext = $tile_format->{$format};
}
else {
    $ext = $tile_format->{"pbf"};
}

my $database_file = "../world/etc/tile/tile-$ext.csv";
my $tile = Extract::TileSize->new( 'database' => $database_file );

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
    Extract::TileSize::FRACTAL_REAL );
$size = int( $size * 1000 + 0.5 ) / 1000;

my $sub_planet = sub_planet(
    {
        "sw_lng" => $lng_sw,
        "sw_lat" => $lat_sw,
        "ne_lng" => $lng_ne,
        "ne_lat" => $lat_ne
    }
);

my $sub_planet_path = $sub_planet->{'sub_planet_path'};
$sub_planet_path =~ s,.*?/([^/]+/+[^/]+)$,$1,;    # double basename

warn
"size: $size, factor $factor, format: $format, ext: $ext, factor_format: $factor_format, ",
  "area: $lng_sw,$lat_sw,$lng_ne,$lat_ne",
  ", sub_planet_path: $sub_planet_path", "\n"
  if $debug >= 2;

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
