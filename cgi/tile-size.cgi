#!/usr/local/bin/perl
# Copyright (c) June 2012 Wolfram Schneider, http://bbbike.org
#
# tile-size.cgi - compute size of an tile from planet.osm

use GIS::Distance::Lite;
use CGI;
use IO::File;
use Data::Dumper;
use lib '../bin';
use TileSize;

use strict;
use warnings;

my $debug = 1;

sub extract_size {
    my %args = @_;
    my $area = $args{'area'};
    my $db   = $args{'db'};

    my ( $x1, $y1, $x2, $y2 ) = split( /,/, $area );
    warn "area: $x1,$y1,$x2,$y2\n" if $debug;

    my $size = 0;
    for my $x ( int($x1) .. int( $x2 + 0.99 ) - 1 ) {
        for my $y ( int($y1) .. int( $y2 + 0.99 ) - 1 ) {
            my $x3     = $x + 1;
            my $y3     = $y + 1;
            my $factor = 1;

            if (   int($x1) < $x1 && int($x1) == $x
                || int($x2) < $x2 && int($x2) == $x
                || int($y1) < $y1 && int($y1) == $y
                || int($y2) < $y2 && int($y2) == $y )
            {
                $factor = 0.5;
            }
            warn "size of area: $x,$y,$x3,$y3 factor: $factor\n" if $debug;
            $size += $factor * $db->{"$x,$y,$x3,$y3"};
        }
    }
    return $size;
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

my $area = $q->param('area') || "10,52,15,59";
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

my $database_file = "../etc/tiles.csv";
my $db            = &parse_db($database_file);

warn Dumper($db) if $debug >= 2;
my $size = &extract_size( 'db' => $db, 'area' => $area );
print "$size\n";

