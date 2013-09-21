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
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my @homepages_localhost = qw[ http://localhost ];
my @homepages           = qw[ http://www.bbbike.org ];
unshift @homepages, @homepages_localhost;

my @cities = qw/Berlin Zuerich Toronto Moscow/;
use constant MYGET => 3;

my @lang = qw/de da  es  fr  hr  nl  pl  pt  ru  zh/;

my $msg = {
    "de" => ["Start- und Zielstra&szlig;e der Route eingeben"],
    "da" => ["Angiv start-og bestemmelsessted gadenavn"],
    "es" => ["Por favor, introduzca de inicio y destino"],
    "fr" => ["S'il vous plaît entrez vous nom de la rue de destination"],
    "hr" => ["Molimo unesite početak i odredište naziv ulice"],
    "nl" => ["Geef start-en straatnaam van uw bestemming"],
    "pl" => ["Proszę podać start i ulicy przeznaczenia nazwę"],
    "pt" => ["Por favor, indique de partida eo destino nome da rua"],
    "ru" => [
"Пожалуйста, введите начало и назначения название улицы"
    ],
    "zh" =>
      ["请输入起始和没有门牌号码</乙>目的地的街道名称的"]
};

if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    my $counter_text = 0;
    foreach my $l (@lang) {
        $counter_text += scalar( @{ $msg->{$l} } );
    }
    $counter_text *= scalar(@cities);

    my $counter_html = ( MYGET * 11 ) + 2;
    my $counter_cities =
      scalar(@cities) * ( MYGET * 2 + 26 ) * ( scalar(@lang) + 1 );
    my $counter_ads = 0;

    # ads only on production system
    foreach my $homepage (@homepages) {
        $counter_ads +=
          scalar( grep { $_ !~ m,^http://www, } $homepage ) *
          ( scalar(@cities) * ( scalar(@lang) + 1 ) );
    }

    plan tests => scalar(@homepages) *
      ( $counter_html + $counter_cities + $counter_text ) - $counter_ads;
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
    my $homepage = shift;

    foreach my $city (@cities) {
        foreach my $lang ( "", @lang ) {
            my $url =
              $lang eq "" ? "$homepage/$city/" : "$homepage/$lang/$city/";
            my $data = _cities( $city, $lang, $url );

            # check for correct translations
            if ( $lang ne "" ) {
                foreach my $text ( @{ $msg->{$lang} } ) {
                    like( $data, qr|$text|,
                        "check translations $url -> $text" );
                }
            }
        }
    }
}

sub _cities {
    my $city = shift;
    my $lang = shift;
    my $url  = shift;

    my $homepage = $url;
    $homepage =~ s,(^http://[^/]+).*,$1,;

    my $res     = myget($url);
    my $content = $res->decoded_content;
    my $data    = $content;

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
    like( $res->decoded_content, qr|src="/html/bbbike(-js)?.js"|,
        "bbbike(-js)?.js" );
    like( $res->decoded_content, qr|href="/html/bbbike.css"|, "bbbike.css" );
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

    # only on production systems
    if ( $homepage =~ m,^http://www, ) {
        like( $res->decoded_content, qr|google_ad_client|, "google_ad_client" );
    }

    like( $res->decoded_content, qr|<div id="map"></div>|, "div#map" );
    like( $res->decoded_content, qr|bbbike_maps_init|,     "bbbike_maps_init" );
    like( $res->decoded_content, qr|city = ".+";|,         "city" );
    like( $res->decoded_content, qr|display_current_weather|,
        "display_current_weather" );
    like( $res->decoded_content, qr|displayCurrentPosition|,
        "displayCurrentPosition" );
    like( $res->decoded_content, qr|<div id="footer">|, "footer" );
    like( $res->decoded_content, qr|id="other_cities"|, "other cities" );
    like( $res->decoded_content, qr|</html>|,           "closing </html>" );

    # skip other tests on slow networks (e.g. on mobile phone links)
    return $data if $ENV{BBBIKE_TEST_SLOW_NETWORK};

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

    return $data;
}

sub html {
    my $homepage = shift;

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

########################################################################
# main
#

foreach my $homepage (@homepages) {
    diag "check homepage $homepage";
    &cities($homepage);
    &html($homepage);
}

__END__
