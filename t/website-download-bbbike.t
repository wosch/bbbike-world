#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use BBBike::Test;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $test  = BBBike::Test->new();
my $debug = 0;

my @homepages = "https://download.bbbike.org";

my @cities = map { chomp; $_ } (`./world/bin/bbbike-db --list`);

# only the first 4 cities
if ( $ENV{BBBIKE_TEST_FAST} ) {
    @cities = @cities[ 0 .. 3 ];
}

sub get_bbbike_files {
    my $url    = shift;
    my $cities = shift;
    my @cities = @$cities;

    my @ext = qw/osm.csv.xz
      osm.garmin-osm.zip
      osm.gz
      osm.geojson.xz
      osm.navit.zip
      osm.pbf
      osm.shp.zip
      poly/;

    my @urls;
    foreach my $city (@cities) {
        foreach my $e (@ext) {
            push @urls, "$url/$city/$city.$e";
        }
        push @urls, "$url/$city/CHECKSUM.txt";
    }

    return @urls;
}

my @urls;
foreach my $home (@homepages) {
    push @urls, get_bbbike_files( "$home/osm/bbbike", \@cities );
}

# ads only on production system
plan tests => $test->myget_counter * scalar(@urls);

########################################################################
# main
#

diag( "extract downloads URLs to check: " . scalar(@urls) ) if $debug;
foreach my $u (@urls) {
    diag("URL: $u") if $debug >= 2;

    my $size = $u =~ /\.(poly|txt)$/ ? 30 : 10_000;
    $test->myget_head( $u, $size );
}

__END__
