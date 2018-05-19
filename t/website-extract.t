#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use Test::More::UTF8;
use BBBike::Test;
use Extract::Config;

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list(qw/extract dev/);

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my @lang = qw/en de ru es fr/;
my @tags =
  ( '</html>', '<head>', '<body[ >]', '</body>', '</head>', '<html[ >]' );

my @extract_dialog =
  qw/about.html email.html format.html name.html polygon.html search.html select-area.html/;

my $msg = {
    "en" => [ "Wait for email notification", "Name of area to extract" ],
    "de" => [ "Deine E-Mail Adresse", "Punkte zum Polygon hinzuf&uuml;gen" ],
    "fr" => [ "Votre adresse électronique", "Nom de la zone à extraire" ],

    # rest
    "ru"  => [ "Wait for email notification", "Name of area to extract" ],
    "es"  => [ "Wait for email notification", "Name of area to extract" ],
    "XYZ" => [ "Wait for email notification", "Name of area to extract" ],
    ""    => [ "Wait for email notification", "Name of area to extract" ],
};

my $unicode = [
    {
        'path' =>
'/cgi/extract.cgi?lang=en&sw_lng=23.147&sw_lat=42.578&ne_lng=23.177&ne_lat=42.602&format=osm.pbf&oi=1&city=София%2C%20Ингилизка%20махала%2C%20Pernik%2C%20Pernik&layers=B0000T',
        'match' =>
          [qr/value="София, Ингилизка махала, Pernik/]
    },
    {
        'path' =>
'/cgi/extract.cgi?lang=en&sw_lng=23.149&sw_lat=42.579&ne_lng=23.179&ne_lat=42.603&format=osm.pbf&oi=1&city=M%C3%BCnchen%2C%20Landkreis&layers=B0000T',
        'match' => [qr/value="München, Landkreis/]
    }
];

sub page_check_unicode {
    my ( $home_url, $unicode ) = @_;

    foreach my $obj (@$unicode) {
        my $path  = $obj->{'path'};
        my $match = $obj->{'match'};
        my $url   = $home_url . $path;
        my $res   = $test->myget( $url, 9_000 );

        foreach my $text (@$match) {
            like( $res->decoded_content, $text, "match unicode: $text $url" );
        }
    }
}

sub page_check {
    my $home_url = shift;
    my $script_url = shift || "$home_url/cgi/extract.cgi";

    # check for known languages
    foreach my $l (@lang) {
        my $url = "$script_url?lang=$l";
        my $res = $test->myget( $url, 9_000 );

        # correct translations?
        foreach my $text ( @{ $msg->{$l} } ) {
            like( $res->decoded_content, qr/$text/,
                "bbbike extract translation: $text url:$url" );
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
                "bbbike extract html tag: $tag url:$script_url" );
        }

        like( $res->decoded_content, qr|polygon_update|, "bbbike extract" );

        $test->myget( "$home_url/html/jquery/jquery-ui-1.9.1.custom.min.js",
            1_000 );
        $test->myget( "$home_url/html/jquery/jquery-1.7.1.min.js", 20_000 );

        #myget( "$home_url/html/jquery/jquery.cookie-1.3.1.js",        2_000 );
        $test->myget( "$home_url/html/OpenLayers/2.12/OpenStreetMap.js",
            2_800 );
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
    $test->myget( "$home_url/garmin/", 268 );

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
    &page_check_unicode( $home_url, $unicode );
}

# check garmin legend: https://extract.bbbike.org/garmin/bbbike/
&garmin_check( $homepages_localhost[0] );

done_testing;

__END__
