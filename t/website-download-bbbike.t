#!/usr/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use utf8;
use Test::More;
use LWP;
use LWP::UserAgent;

use strict;
use warnings;

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }

    #if ( $ENV{BBBIKE_TEST_FAST} ) { print "1..0 # skip due fast test\n"; exit; }
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";
my $debug = 0;

my @homepages = "http://download.bbbike.org";

my @cities = map { chomp; $_ } (`./world/bin/bbbike-db --list`);

# only the first 4 cities
if ($ENV{BBBIKE_TEST_FAST}) {
    @cities = @cities[0..3];
}


sub get_bbbike_files {
    my $url  = shift;
    my $cities = shift;
    my @cities = @$cities;
   
    my @ext = qw/osm.csv.xz
osm.garmin-bbbike.zip
osm.garmin-cycle.zip
osm.garmin-leisure.zip
osm.garmin-osm.zip
osm.gz
osm.navit.zip
osm.obf.zip
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

use constant MYGET => 3;

my @urls;
foreach my $home (@homepages) {
    push @urls, get_bbbike_files("$home/osm/bbbike", \@cities);
}

# ads only on production system
plan tests => MYGET * scalar(@urls);

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget_head {
    my $url  = shift;
    my $size = shift;

    $size = 1 if !defined $size;

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

diag( "extract downloads URLs to check: " . scalar(@urls) ) if $debug;
foreach my $u (@urls) {
    diag("URL: $u") if $debug >= 2;
    myget_head($u);
}

__END__
