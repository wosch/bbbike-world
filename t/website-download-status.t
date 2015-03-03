#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

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
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my $debug = 1;

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://download.bbbike.org http://download1.bbbike.org http://dev1.bbbike.org http://dev2.bbbike.org ];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my @lang = qw/en de/;
my @tags =
  ( '</html>', '<head>', '<body[ >]', '</body>', '</head>', '<html[ >]' );
my @elements = qw[
  /community.html
  /extract.html
  /html/bbbike.css
  /html/extract-download.css
  /html/extract-download.js
  /html/jquery/jquery-1.8.3.min.js
  /html/OpenLayers/2.12/OpenLayers-min.js
  /html/OpenLayers/2.12/OpenStreetMap.js
  /images/btn_donateCC_LG.gif
  /images/srtbike16.gif];

my $msg = {
    "en" => [
        "Newest extracts are first", "Number of extracts",
        "Last update",               "help",
        "donate",                    "Statistic"
    ],
    "de" => [
        "Neueste Extrakte zuerst", "Anzahl der Extrakte",
        "Letzte Aktualisierung",   "hilfe",
        "spenden",                 "Statistik"
    ],
    "XYZ" => [
        "Newest extracts are first", "Number of extracts",
        "Last update",               "help",
        "donate",                    "Statistic"
    ],
    "" => [
        "Newest extracts are first", "Number of extracts",
        "Last update",               "help",
        "donate",                    "Statistic"
    ],
};

use constant MYGET => 3;

# to complicated to maintain the exact numbers, ignore it
plan 'no_plan';

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget {
    my $url  = shift;
    my $size = shift;

    $size = 10_000 if !defined $size;

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200" );

    my $content = $res->decoded_content();
    cmp_ok( length($content), ">", $size, "greather than $size for URL $url" );

    return $res;
}

sub page_check {
    my $home_url = shift;
    my $script_url = shift || "$home_url/cgi/download.cgi";

    # check for known languages
    foreach my $l (@lang) {
        my $res = myget( "$script_url?lang=$l", 3_000 );

        # correct translations?
        foreach my $text ( @{ $msg->{$l} } ) {
            like( $res->decoded_content, qr/$text/,
                "bbbike extract download translation" );
        }
    }

    # check for unknown language in parameter
    foreach my $l ( "XYZ", "" ) {
        my $url = "$script_url?lang=$l";
        my $res = myget( $url, 3_000 );

        # correct translations?
        foreach my $text ( @{ $msg->{$l} } ) {
            like( $res->decoded_content, qr/$text/,
                "bbbike extract download translation: $url" );
        }
    }

    myget( "$home_url/html/extract-download.css", 3_000 );
    myget( "$home_url/html/extract-download.js",  6_000 );

    my $res = myget( "$script_url", 5_000 );
    like( $res->decoded_content, qr|id="map"|,   "bbbike extract download" );
    like( $res->decoded_content, qr|id="nomap"|, "bbbike extract download" );

 #like( $res->decoded_content, qr|id="social"|,     "bbbike extract download" );
    like( $res->decoded_content, qr| content="text/html; charset=utf-8"|,
        "charset" );
    like( $res->decoded_content, qr| http-equiv="Content-Type"|,
        "Content-Type" );
    like( $res->decoded_content, qr|date=12h|,
        "bbbike extract download date 12h" );
    like( $res->decoded_content, qr|date=24h|,
        "bbbike extract download date 24h" );
    like( $res->decoded_content, qr[^36h |],
        "bbbike extract download date 36h" );
    like( $res->decoded_content, qr|date=48h|,
        "bbbike extract download date 48h" );
    like( $res->decoded_content, qr|date=72h|,
        "bbbike extract download date 72h" );

    foreach my $tag (@tags) {
        like( $res->decoded_content, qr|$tag|,
            "bbbike extract html tag: $tag" );
    }

    foreach my $element (@elements) {
        like( $res->decoded_content, qr|$element|,
            "bbbike extract element: $element" );
    }

    if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        myget( "$home_url/html/jquery/jquery-1.8.3.min.js",        20_000 );
        myget( "$home_url/html/OpenLayers/2.12/OpenStreetMap.js",  3_000 );
        myget( "$home_url/html/OpenLayers/2.12/OpenLayers-min.js", 500_000 );
    }
}

sub garmin_check {
    my $home_url = shift;

    sub legend {
        my $res = shift;

        my @t = ( @tags, '<table[ >]', '<table[ >]' );
        foreach my $tags (@t) {
            like( $res->decoded_content, qr|$tags|,
                "bbbike garmin legend $tags" );
        }
    }
    myget( "$home_url/garmin/", 300 );

    legend( myget( "$home_url/garmin/bbbike/",   18_000 ) );
    legend( myget( "$home_url/garmin/leisure/",  25_000 ) );
    legend( myget( "$home_url/garmin/cyclemap/", 4_700 ) );
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{
    diag "checked site: $home_url" if $debug >= 1;
    &page_check($home_url);
}

__END__
