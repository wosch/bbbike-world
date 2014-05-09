#!/usr/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use utf8;
use Test::More;
use LWP;
use LWP::UserAgent;

use strict;
use warnings;

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_FAST} ) {
        print "1..0 # skip due fast test\n";
        exit;
    }
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my @homepages = qw[
  http://download.bbbike.org
  http://download1.bbbike.org
  http://download2.bbbike.org
];

use constant MYGET => 3;

my $urls = [
    [ "/osm/planet/planet-latest.osm.bz2.md5",            55 ],
    [ "/osm/planet/planet-latest.osm.pbf.md5",            55 ],
    [ "/osm/planet/planet-latest.osm.bz2",                36_000_000_000 ],
    [ "/osm/planet/planet-latest.osm.pbf",                16_000_000_000 ],
    [ "/bbbike/BBBike-3.18-devel-Intel.dmg",              33_000 ],
    [ "/bbbike/data-osm/Ottawa.tbz",                      32_000 ],
    [ "/favicon.ico",                                     1_000 ],
    [ "/robots.txt",                                      100 ],
    [ "/sitemap.xml.gz",                                  1_000 ],
    [ "/index.html",                                      800 ],
    [ "/osm/srtm/e40/planet-srtm-e40.osm.pbf",            14_000_000 ],
    [ "/osm/srtm/e40/CHECKSUM.txt",                       50 ],
    [ "/osm/srtm/e40/latlon/Lat9Lon98Lat10Lon99.osm.pbf", 2_000_000 ],
    [ "/osm/srtm/e40/latlon/CHECKSUM.txt.gz",             1_000_000 ],
    [ "/osm/index.html",                                  1_000 ],
    [ "/osm/extract/",                                    1_000 ],
    [ "/osm/planet/HEADER.txt",                           600 ],
];

# ads only on production system
plan tests => scalar(@homepages) * MYGET * scalar(@$urls);

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget_head {
    my $url  = shift;
    my $size = shift;

    $size = 10_000 if !defined $size;

    my $req = HTTP::Request->new( HEAD => $url );
    my $res = $ua->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200" );

    my $content_length = $res->content_length;

    #diag("content_length: " . $content_length);
    cmp_ok( $content_length, ">", $size, "greather than $size" );

    return $res;
}

########################################################################
# main
#

foreach my $homepage (@homepages) {
    foreach my $u (@$urls) {
        myget_head( $homepage . $u->[0], $u->[1] );
    }
}

__END__
