#!/usr/local/bin/perl
# Copyright (c) June 2012-2013 Wolfram Schneider, http://bbbike.org
#
# tile-fixme.pl - guess size based on factor of known size of osm.pbf

use IO::File;
use Getopt::Long;
use Data::Dumper;

use lib 'world/bin';
use lib '.';
use TileSize;

use strict;
use warnings;

my $debug = 2;

sub to_csv {
    my $key = shift;
    my $kb  = shift;

    my ( $lng_sw, $lat_sw ) = split ",", $key;
    my $lng_ne = $lng_sw + 1;
    my $lat_ne = $lat_sw + 1;

    return
      $kb . "\t" . join( " ", ( $lng_sw, $lat_sw, $lng_ne, $lat_ne ) ) . "\n";
}

######################################################################
# GET /w/api.php?namespace=1&q=berlin HTTP/1.1
#
# param alias: q: query, search
#              ns: namespace
#

binmode( \*STDERR, ":raw" );
binmode( \*STDOUT, ":raw" );

my $help;
my $format;

my @format =
  qw/garmin-cycle.zip mapsforge-osm.zip navit.zip obf.zip osm.gz shp.zip/;

sub usage () {
    <<EOF;
    
usage: $0 [options] --format=format tile-pbf.csv tile-garmin-cycle.csv

--debug=0..2      debug option
--format=format   @{[ join " | ", @format ]}

EOF
}

GetOptions(
    "debug=i"  => \$debug,
    "format=s" => \$format,
    "help"     => \$help,
) or die usage;

my $database_pbf   = shift;
my $database_fixme = shift;

die &usage if $help;
die "missinag database argument" . &usage
  if ( !$database_pbf || !$database_fixme );
die "missinag format argument" . &usage if !$format;

my $tile_pbf   = TileSize->new( 'database' => $database_pbf );
my $tile_fixme = TileSize->new( 'database' => $database_fixme );

#warn Dumper($tile_fixme->{_size});
while ( my ( $key, $val ) = each %{ $tile_fixme->{_size} } ) {
    print to_csv( $key, $val ) if $val > -1;
}

1;
