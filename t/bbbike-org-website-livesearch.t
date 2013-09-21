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
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my @homepages_localhost = qw[ http://localhost ];
my @homepages           = qw[ http://www.bbbike.org ];

unshift @homepages, @homepages_localhost;

use constant MYGET => 3;

# ads only on production system
plan tests => scalar(@homepages) * ( MYGET + 16 );

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

sub livesearch_extract {
    my $url = shift;

    my $res     = myget( $url, 5_000 );
    my $content = $res->decoded_content;
    my $data    = $content;

    like( $res->decoded_content,
        qr|Content-Type" content="text/html; charset=utf-8"|, "charset" );

    #like( $res->decoded_content, qr|rel="shortcut|, "icon" );
    like( $res->decoded_content, qr|src="(..)?/html/bbbike(-js)?.js"|,
        "bbbike(-js)?.js" );
    like( $res->decoded_content, qr|src="(..)?/html/jquery/.*?.js"|,
        "jquery.js" );
    like( $res->decoded_content, qr|href="(..)?/html/bbbike.css"|,
        "bbbike.css" );

    like( $res->decoded_content, qr|<div id="map"></div>|, "div#map" );
    like( $res->decoded_content, qr|bbbike_maps_init|,     "bbbike_maps_init" );
    like( $res->decoded_content, qr|city = ".+";|,         "city" );

    like( $res->decoded_content, qr|bbbike_maps_init|, "bbbike_maps_init" );
    like( $res->decoded_content, qr|plotRoute|,        "plotRoute" );
    like(
        $res->decoded_content,
        qr|Cycle Route Statistic|,
        "Cycle Route Statistic"
    );
    like(
        $res->decoded_content,
        qr|Number of unique routes:|,
        "Number of unique routes:"
    );
    like( $res->decoded_content, qr|median:|,    "median:" );
    like( $res->decoded_content, qr|jumpToCity|, "jumpToCity" );
    like( $res->decoded_content, qr|>today<|,    ">today<" );

    like( $res->decoded_content, qr|<div id="footer">|, "footer" );
    like( $res->decoded_content, qr|</html>|,           "closing </html>" );

    return $data;
}

########################################################################
# main
#

foreach my $homepage (@homepages) {

    #diag "checked homepage $homepage";
    &livesearch_extract("$homepage/cgi/livesearch.cgi");
}

__END__
