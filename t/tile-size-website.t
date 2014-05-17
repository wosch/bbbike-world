#!/usr/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use Test::More;
use strict;
use warnings;

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

use LWP;
use LWP::UserAgent;

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://extract.bbbike.org http://extract2.bbbike.org http://dev1.bbbike.org http://dev2.bbbike.org];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my $formats = {
    'osm.pbf' => 'Protocolbuffer (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
    'osm.xz'  => "OSM XML 7z (xz)",

    'shp.zip'            => "Shapefile (Esri)",
    'garmin-osm.zip'     => "Garmin OSM",
    'garmin-cycle.zip'   => "Garmin Cycle",
    'garmin-leisure.zip' => "Garmin Leisure",

    'garmin-bbbike.zip' => "Garmin BBBike",
    'navit.zip'         => "Navit",
    'obf.zip'           => "Osmand (OBF)",
    'o5m.gz'            => "o5m gzip'd",
    'o5m.xz'            => "o5m 7z (xz)",

    #'o5m.bz2'           => "o5m bzip'd",
    'csv.gz' => "csv gzip'd",
    'csv.xz' => "csv 7z (xz)",

    "opl.xz" => "pbf",

    'mapsforge-osm.zip' => "Mapsforge OSM",

    'srtm-europe.osm.pbf'         => 'SRTM Europe PBF',
    'srtm-europe.garmin-srtm.zip' => 'SRTM Europe Garmin',
    'srtm-europe.obf.zip'         => 'SRTM Europe Osmand',

    'srtm.osm.pbf'         => 'SRTM PBF',
    'srtm.garmin-srtm.zip' => 'SRTM Garmin',
    'srtm.obf.zip'         => 'SRTM Osmand',
};

use constant MYGET => 3;

plan tests => scalar( keys %$formats ) * scalar(@homepages) * ( MYGET + 1 );

#plan 'no_plan';

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget {
    my $url  = shift;
    my $size = shift;

    $size = 11 if !defined $size;

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200" );

    my $content = $res->decoded_content();
    cmp_ok( length($content), ">", $size, "greather than $size for URL $url" );

    return $res;
}

sub page_check {
    my $home_url   = shift;
    my $script_url = shift
      || "$home_url/cgi/tile-size.cgi?lat_sw=51.775&lng_sw=11.995&lat_ne=53.218&lng_ne=14.775";

    foreach my $f ( keys %$formats ) {
        my $res = myget( "$script_url&format=$f", 11 );

        # {"size": 65667.599 }
        # {"size": 0 }
        like( $res->decoded_content, qr|^{"size": [\d\.]+ }$|, "size" );
    }
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{
    &page_check($home_url);
}

__END__
