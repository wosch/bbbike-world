#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_NO_PRODUCTION} ) {
        print "1..0 # skip due no network or non production\n";
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
plan tests => scalar(@homepages) * ( $test->myget_counter + 13 );

sub livesearch_extract {
    my $url = shift;

    my $res     = $test->myget( $url, 4_600 );
    my $content = $res->decoded_content();

    like( $content, qr|Content-Type" content="text/html; charset=utf-8"|,
        "charset" );

    #like( $content, qr|rel="shortcut|, "icon" );
    like( $content, qr|src="(..)?/html/bbbike(-js)?.js"|, "bbbike(-js)?.js" );
    like( $content, qr|href="(..)?/html/bbbike.css"|,     "bbbike.css" );

    like( $content, qr|<div id="map"></div>|, "div#map" );
    like( $content, qr|bbbike_maps_init|,     "bbbike_maps_init" );
    like( $content, qr|city = ".+";|,         "city" );

    like( $content, qr|bbbike_maps_init|, "bbbike_maps_init" );
    like( $content, qr|plotRoute|,        "plotRoute" );
    like( $content, qr|unique total:|,    "unique total:" );
    like( $content, qr|jumpToCity|,       "jumpToCity" );
    like( $content, qr|>today<|,          ">today<" );

    like( $content, qr|<div id="footer">|, "footer" );
    like( $content, qr|</html>|,           "closing </html>" );

    return $content;
}

########################################################################
# main
#

foreach my $homepage (@homepages) {

    #diag "checked homepage $homepage";
    &livesearch_extract("$homepage/cgi/livesearch-extract.cgi");
}

__END__
