#!/usr/local/bin/perl
# Copyright (c) June 2012 Wolfram Schneider, http://bbbike.org
#
# tile-size.cgi - compute size of an tile from planet.osm

use CGI;
use IO::File;
use lib '../bin';
use TileSize;

use strict;
use warnings;

my $debug = 1;

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
    -type    => 'text/javascript',
    -charset => 'utf-8',
    -expires => $expire,
);

my $database_file = "../etc/tile.csv";
my $tile          = TileSize->new( 'database' => $database_file );
my $lng_sw        = $q->param("lng_sw");
my $lat_sw        = $q->param("lat_sw");
my $lng_ne        = $q->param("lng_ne");
my $lat_ne        = $q->param("lat_ne");
my $factor        = $q->param("factor") || 1;

# short cut "area=lat,lng,lat,lng"
if ( defined $area ) {
    ( $lng_sw, $lat_sw, $lng_ne, $lat_ne ) = split /,/, $area;
}

if (   !defined $lng_sw
    || !defined $lat_sw
    || !defined $lng_ne
    || !defined $lat_ne )
{
    print "{}";
    warn "Missing lat,lng parameter: $lng_sw,$lat_sw => $lng_ne,$lat_ne\n";
    exit 0;
}
$factor = 1 if $factor < 0 || $factor > 100;

my $size = $tile->area_size( $lng_sw, $lat_sw, $lng_ne, $lat_ne, 2 );
print qq|{"size": $size }\n|;

1;
