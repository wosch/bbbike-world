#!/usr/local/bin/perl
# Copyright (c) June 2012-2016 Wolfram Schneider, https://bbbike.org
#
# tile-padding.pl - guess size based on factor of known size of osm.pbf

use IO::File;
use Getopt::Long;
use Data::Dumper;

use lib qw(world/lib ../lib);
use Extract::TileSize;

use strict;
use warnings;

my $debug = 0;
$Extract::TileSize::use_cache = 0;

sub to_csv {
    my $key = shift;
    my $kb  = shift;

    my ( $lng_sw, $lat_sw ) = split ",", $key;
    my $lng_ne = $lng_sw + 1;
    my $lat_ne = $lat_sw + 1;

    return
      $kb . "\t" . join( " ", ( $lng_sw, $lat_sw, $lng_ne, $lat_ne ) ) . "\n";
}

sub guess_format {
    my $file = shift;

    my $format = "";

    if ( $file =~ m,([^/]+\.(zip|xz|gz))\.csv$, ) {
        $format = $1;
        warn "Guessed format: $format\n" if $debug >= 1;
        return $format;
    }

    warn "Cannot guess format: '$file'\n";
    return $format;
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
my $min_size = 0;

my @format =
  qw/garmin-cycle.zip garmin-srtm.zip garmin-osm.zip garmin-leisure.zip mapsforge-osm.zip obf.zip osm.gz shp.zip csv.xz mbtiles-openmaptiles.zip/;

sub usage () {
    <<EOF;

usage: $0 [options] --format=format pbf.csv garmin-osm.csv

--debug=0..2      debug option
--format=format   @{[ join " | ", @format ]}
--min-size=0..1024 minimum size, default $min_size

EOF
}

GetOptions(
    "debug=i"    => \$debug,
    "format=s"   => \$format,
    "min-size=s" => \$min_size,
    "help"       => \$help,
) or die usage;

my $database_pbf     = shift;
my $database_padding = shift;

die &usage if $help;
die "missinag database argument" . &usage
  if ( !$database_pbf || !$database_padding );

if ( !$format ) {
    $format = guess_format($database_padding);
}
die "missing format argument" . &usage if !$format;

warn "tile pbf db: $database_pbf, tile padding db: $database_padding\n"
  if $debug >= 1;
my $tile_pbf =
  Extract::TileSize->new( 'database' => $database_pbf, 'debug' => $debug );
my $tile_padding =
  Extract::TileSize->new( 'database' => $database_padding, 'debug' => $debug );

die "unknown format '$format'" . &usage
  if !exists $Extract::TileSize::factor->{$format};

warn Dumper( $tile_padding->{_size} ) if $debug >= 2;

# original data
my %hash;
while ( my ( $key, $val ) = each %{ $tile_padding->{_size} } ) {
    if ( $val >= $min_size ) {
        print to_csv( $key, $val );
        $hash{$key} = 1;
    }
}

# guess misssing size based on PBF database
my $factor = $tile_padding->{'factor'}->{$format};
while ( my ( $key, $val ) = each %{ $tile_pbf->{_size} } ) {
    if ( !exists $tile_padding->{_size}->{$key} ) {
        print to_csv( $key, int( $val * $factor + 0.5 ) )
          if $val >= $min_size && !$hash{$key};
    }
}

1;
