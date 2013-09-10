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

my $homepage = 'http://download.bbbike.org/osm/bbbike';
my @cities   = qw/Berlin Zuerich Toronto Moscow/;
use constant MYGET => 3;

my $garmin = 1;    # 0, 1

if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    plan tests => scalar(@cities) * ( MYGET * 4 + 5 + 5 * $garmin );
}
else {
    plan 'no_plan';
}

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget {
    my $url  = shift;
    my $size = shift;

    $size = 30_000 if !defined $size;

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

        my $path = $homepage;
        $path =~ s,http://.*?/,/,;

        like( $res->decoded_content,
            qr|Content-Type" content="text/html; charset=utf-8"|, "charset" );

        #like( $res->decoded_content, qr|rel="shortcut|, "icon" );
        like( $res->decoded_content, qr|src=".*/html/bbbike.js"|, "bbbike.js" );
        like( $res->decoded_content, qr|href=".*/html/bbbike.css"|,
            "bbbike.css" );

#like( $res->decoded_content, qr|href="http://twitter.com/BBBikeWorld"|, "twitter" );
        like( $res->decoded_content, qr|<div id="map"></div>|, "div#map" );
        like( $res->decoded_content, qr|bbbike_maps_init|, "bbbike_maps_init" );
        like( $res->decoded_content, qr|city = ".+";|,     "city" );
        like( $res->decoded_content, qr|<div id="footer">|, "footer" );
        like( $res->decoded_content, qr|id="more_cities"|,  "more cities" );
        like( $res->decoded_content, qr|</html>|,           "closing </html>" );

        like(
            $res->decoded_content,
qr|Start bicycle routing for .*?href="http://www.bbbike.org/$city/">|,
            "routing link"
        );

        foreach my $ext (qw/gz pbf/) {
            like( $res->decoded_content, qr|($path/$city)?/$city.osm.$ext"|,
                "$path/$city/$city.osm.$ext" );
        }

        if ($garmin) {
            foreach my $ext (
                qw/osm.garmin-cycle.zip osm.garmin-leisure.zip osm.garmin-osm.zip osm.shp.zip osm.navit.zip poly/
              )
            {
                like( $res->decoded_content, qr|($path/$city)?/$city.$ext"|,
                    "$path/$city/$city.$ext" );
            }
        }

        like( $res->decoded_content, qr|($path/$city)?/CHECKSUM.txt"|,
            "CHECKSUM.txt" );
    }
}

&cities;

__END__

