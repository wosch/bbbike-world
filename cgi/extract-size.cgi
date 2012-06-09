#!/usr/local/bin/perl
# Copyright (c) June 2012 Wolfram Schneider, http://bbbike.org
#
# planet-size.cgi - compute size of an extract from planet.osm

use GIS::Distance::Lite;
use CGi;
use IO::File;
use Data::Dumper;

use strict;
use warnings;

my $debug = 0;

sub extract_size {
    my %args = @_;
    my $area = $args{'area'};
    my $db   = $args{'db'};

    return $db->{$area};
}

# ($lat1, $lon1 => $lat2, $lon2);
sub square_km {
    my ( $x1, $y1, $x2, $y2 ) = @_;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 ) / 1000;
    my $width  = GIS::Distance::Lite::distance( $x1, $y1 => $x2, $y1 ) / 1000;

    return int( $height * $width );
}

sub parse_db {
    my $file = shift;

    my %hash;

    my $fh = new IO::File $file, "r" or die "open $file: $!\n";
    binmode $fh, ":raw";

    while (<$fh>) {
        my ( $size, $x1, $y1, $x2, $y2 ) = split;
        $hash{"$x1,$y1,$x2,$y2"} = $size;
    }
    $fh->close;

    return \%hash;
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

my $area = $q->param('area') || "14,14,15,15";
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

my $database_file = "../etc/heatmap/heatmap.txt";
my $db = &parse_db($database_file );

warn Dumper($db) if $debug >=2;
my $size = &extract_size( 'db' => $db, 'area' => $area );
print $size;

