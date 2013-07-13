#!/usr/local/bin/perl
# Copyright (c) June 2012-2013 Wolfram Schneider, http://bbbike.org
#
# tile-fixme.pl - guess size based on factor of known size of osm.pbf

use IO::File;
use Getopt::Long;
use lib 'world/bin';
use lib '.';
use TileSize;

use strict;
use warnings;

my $debug = 2;

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

1;
