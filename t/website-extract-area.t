#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network or non production\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use BBBike::Test;
use Extract::Config;

use strict;
use warnings;

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list(qw/www dev/);

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

# ads only on production system
plan tests => scalar(@homepages) * ( $test->myget_counter + 18 ) - 1;

sub livesearch_extract {
    my $url = shift;

    my $res = $test->myget( $url, 4_600 );
    my $content = $res->decoded_content();

    diag "url: $url";

    like(
        $content,
qr[content="text/html; charset=utf-8"|charset=utf-8" content="text/html"],
        "charset"
    );
    like(
        $content,
qr[<meta content="nofollow" name="robots" />|<meta name="robots" content="nofollow" />],
        "robots: nofollow"
    );

    #like( $content, qr|rel="shortcut|, "icon" );
    like( $content, qr|src="(..)?/html/bbbike(-js)?.js"|, "bbbike(-js)?.js" );
    like( $content, qr|href="(..)?/html/bbbike.css"|,     "bbbike.css" );

    like( $content, qr|<div id="map"></div>|, "div#map" );
    like( $content, qr|bbbike_maps_init|,     "bbbike_maps_init" );
    like( $content, qr|city = ".+";|,         "city" );

    like( $content, qr|bbbike_maps_init|, "bbbike_maps_init" );
    like( $content, qr|plotRoute|,        "plotRoute" );

    like( $content, qr|plotRoute|, "plotRoute" );

    # on a local instance, don't expect extracted files
    if ( $url !~ /localhost/ ) {
        like( $content, qr|\.osm\.pbf<|, ".osm.pbf" );
    }

    like( $content, qr|www.bbbike.org/community.html">donate</a>|, ">donate<" );
    like( $content, qr|OSM extracts for |, "OSM extracts for" );
    like( $content, qr|>help<|,            ">help<" );
    like( $content, qr|>screenshots<|,     ">screenshots<" );
    like( $content, qr|>extracts<|,        ">extracts<" );

    like( $content, qr|<div id="footer">|, "footer" );
    like( $content, qr|</html>|,           "closing </html>" );

    return $content;
}

########################################################################
# main
#

foreach my $homepage (@homepages) {

    #diag "checked homepage $homepage";
    &livesearch_extract("$homepage/cgi/area.cgi");
}

__END__
