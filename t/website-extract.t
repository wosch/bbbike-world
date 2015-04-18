#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

use Test::More;
use lib qw(./world/lib ../lib);
use BBBikeTest;

my $test = BBBikeTest->new();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://extract.bbbike.org http://extract2.bbbike.org http://dev1.bbbike.org http://dev2.bbbike.org ];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my @lang = qw/en de ru es fr/;
my @tags =
  ( '</html>', '<head>', '<body[ >]', '</body>', '</head>', '<html[ >]' );

my @extract_dialog =
  qw/about.html email.html format.html name.html polygon.html select-area.html/;

my $msg = {
    "de" => [ "Deine E-Mail Adresse", "Punkte zum Polygon hinzuf&uuml;gen" ],
    "en"  => [ "Wait for email notification", "Name of area to extract" ],
    "ru"  => [ "Wait for email notification", "Name of area to extract" ],
    "es"  => [ "Wait for email notification", "Name of area to extract" ],
    "fr"  => [ "Wait for email notification", "Name of area to extract" ],
    "XYZ" => [ "Wait for email notification", "Name of area to extract" ],
    ""    => [ "Wait for email notification", "Name of area to extract" ],
};

# to complicated to maintain the exact numbers, ignore it
plan 'no_plan';

sub page_check {
    my $home_url = shift;
    my $script_url = shift || "$home_url/cgi/extract.cgi";

    # check for known languages
    foreach my $l (@lang) {
        my $res = $test->myget( "$script_url?lang=$l", 9_000 );

        # correct translations?
        foreach my $text ( @{ $msg->{$l} } ) {
            like( $res->decoded_content, qr/$text/,
                "bbbike extract translation" );
        }
    }

    foreach my $l (@lang) {
        foreach my $file (@extract_dialog) {
            $test->myget( "$home_url/extract-dialog/$l/$file", 420 );
        }
    }

    # check for unknown language in parameter
    foreach my $l ( "XYZ", "" ) {
        my $url = "$script_url?lang=$l";
        my $res = $test->myget( $url, 9_000 );

        # correct translations?
        foreach my $text ( @{ $msg->{$l} } ) {
            like( $res->decoded_content, qr/$text/,
                "bbbike extract translation: $url" );
        }
        like(
            $res->decoded_content,
            qr|href='/extract-dialog/en/select-area.html'|,
            "default to english language: $url"
        );
    }

    foreach my $l (@lang) {
        foreach my $file (@extract_dialog) {
            $test->myget( "$home_url/extract-dialog/$l/$file", 420 );
        }
    }

    $test->myget( "$home_url/html/extract.css",         3_000 );
    $test->myget( "$home_url/html/extract.js",          1_000 );
    $test->myget( "$home_url/extract.html",             12_000 );
    $test->myget( "$home_url/extract-screenshots.html", 4_000 );

    if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        my $res = $test->myget( "$script_url", 10_000 );
        like( $res->decoded_content, qr|id="map"|,           "bbbike extract" );
        like( $res->decoded_content, qr|polygon_update|,     "bbbike extract" );
        like( $res->decoded_content, qr|"garmin-cycle.zip"|, "bbbike extract" );
        like( $res->decoded_content, qr| content="text/html; charset=utf-8"|,
            "charset" );
        like( $res->decoded_content, qr| http-equiv="Content-Type"|,
            "Content-Type" );

        foreach my $tag (@tags) {
            like( $res->decoded_content, qr|$tag|,
                "bbbike extract html tag: $tag" );
        }

        like( $res->decoded_content, qr|polygon_update|, "bbbike extract" );

        $test->myget( "$home_url/html/jquery/jquery-ui-1.9.1.custom.min.js",
            1_000 );
        $test->myget( "$home_url/html/jquery/jquery-1.7.1.min.js", 20_000 );

        #myget( "$home_url/html/jquery/jquery.cookie-1.3.1.js",        2_000 );
        $test->myget( "$home_url/html/OpenLayers/2.12/OpenStreetMap.js",
            3_000 );
        $test->myget( "$home_url/html/OpenLayers/2.12/Here.js", 5_000 );
        $test->myget( "$home_url/html/OpenLayers/2.12/OpenLayers-min.js",
            500_000 );
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
    $test->myget( "$home_url/garmin/", 300 );

    legend( $test->myget( "$home_url/garmin/bbbike/",   18_000 ) );
    legend( $test->myget( "$home_url/garmin/leisure/",  25_000 ) );
    legend( $test->myget( "$home_url/garmin/cyclemap/", 4_700 ) );
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{

    #diag "checked site: $home_url";
    &page_check($home_url);
}

# check garmin legend: http://extract.bbbike.org/garmin/bbbike/
&garmin_check( $homepages_localhost[0] );

__END__
