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

my $homepage = 'http://www.bbbike.org';
my @cities   = qw/Berlin Zuerich Toronto Moscow/;
use constant MYGET => 3;

if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    plan tests => scalar(@cities) * ( MYGET * 4 ) +
      ( MYGET * 11 ) +
      ( scalar(@cities) * 26 ) + 2;
}
else {
    plan 'no_plan';
}

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
    cmp_ok( length($content), ">", $size, "greather than $size" );

    return $res;
}

sub cities {
    foreach my $city (@cities) {
        my $url = "$homepage/$city/";
        my $res = myget($url);

        like( $res->decoded_content, qr|"real_time"|, "complete html" );
        like( $res->decoded_content,
            qr|Content-Type" content="text/html; charset=utf-8"|, "charset" );
        like( $res->decoded_content, qr|rel="shortcut|, "icon" );
        like( $res->decoded_content,
            qr|type="application/opensearchdescription\+xml" rel="search"|,
            "opensearch" );
        like(
            $res->decoded_content,
qr|type="application/atom\+xml" rel="alternate" href="/feed/bbbike-world.xml|,
            "rss"
        );
        like( $res->decoded_content, qr|src="/html/bbbike-js.js"|,
            "bbbike-js.js" );
        like( $res->decoded_content, qr|href="/html/bbbike.css"|,
            "bbbike.css" );
        like(
            $res->decoded_content,
            qr|<span id="language_switch">|,
            "language switch"
        );
        like( $res->decoded_content, qr|href="http://twitter.com/BBBikeWorld"|,
            "twitter" );
        like( $res->decoded_content, qr|class="mobile_link|, "mobile link" );
        like(
            $res->decoded_content,
            qr|#suggest_start\'\).autocomplete|,
            "autocomplete start"
        );
        like(
            $res->decoded_content,
            qr|#suggest_via\'\).autocomplete|,
            "autocomplete via"
        );
        like(
            $res->decoded_content,
            qr|#suggest_ziel\'\).autocomplete|,
            "autocomplete ziel"
        );
        like(
            $res->decoded_content,
            qr|"/images/spinning_wheel32.gif"|,
            "spinning wheel"
        );
        like( $res->decoded_content, qr|google_ad_client|, "google_ad_client" );
        like( $res->decoded_content, qr|<div id="map"></div>|, "div#map" );
        like( $res->decoded_content, qr|bbbike_maps_init|, "bbbike_maps_init" );
        like( $res->decoded_content, qr|city = ".+";|,     "city" );
        like( $res->decoded_content, qr|display_current_weather|,
            "display_current_weather" );
        like( $res->decoded_content, qr|displayCurrentPosition|,
            "displayCurrentPosition" );
        like( $res->decoded_content, qr|<div id="footer">|, "footer" );
        like( $res->decoded_content, qr|id="other_cities"|, "other cities" );
        like( $res->decoded_content, qr|</html>|,           "closing </html>" );

        # skip other tests on slow networks (e.g. on mobile phone links)
        next if $ENV{BBBIKE_TEST_SLOW_NETWORK};

        $url = "$homepage/en/$city/";
        myget($url);
        $url = "$homepage/ru/$city/";
        myget($url);
        $url = "$homepage/de/$city/";

        $res = myget( "$homepage/osp/$city.xml", 100 );
        like(
            $res->decoded_content,
            qr|<InputEncoding>UTF-8</InputEncoding>|,
            "opensearch input encoding utf8"
        );
        like(
            $res->decoded_content,
            qr|template="http://www.bbbike.org/cgi/api.cgi\?sourceid=|,
            "opensearch template"
        );
        like(
            $res->decoded_content,
            qr|http://www.bbbike.org/images/srtbike16.gif</Image>|,
            "opensearch icon"
        );
    }
}

sub html {
    myget( "$homepage/osp/Zuerich.en.xml", 100 );
    myget( "$homepage/osp/Toronto.de.xml", 100 );
    myget( "$homepage/osp/Moscow.de.xml",  100 );
    myget( "$homepage/osp/Moscow.en.xml",  100 );

    myget( "$homepage/html/bbbike.css", 7_000 );
    myget( "$homepage/html/devbridge-jquery-autocomplete-1.1.2/shadow.png",
        1_000 );

    if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        my $res = myget( "$homepage/html/bbbike-js.js", 100_000 );
        like( $res->decoded_content, qr|#BBBikeGooglemap|, "bbbike js" );
        like( $res->decoded_content, qr|downloadUrl|,      "bbbike js" );

        myget( "$homepage/html/streets.css", 2_000 );
        myget( "$homepage/html/luft.css",    3_000 );
        myget(
"$homepage/html/devbridge-jquery-autocomplete-1.1.2/jquery.autocomplete-min.js",
            1_000
        );
        myget( "$homepage/html/jquery/jquery-1.4.2.min.js", 20_000 );
    }
}

&cities;
&html;

__END__

