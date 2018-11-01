#!/usr/local/bin/perl
# Copyright (c) Sep 2018-2018 Wolfram Schneider, https://bbbike.org

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
use URI;
use CGI;
use Test::More;
use Test::More::UTF8;
use BBBike::Test;
use Extract::Config;
use GIS::Distance::Lite;

use strict;
use warnings;

my $debug          = 0;
my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list(qw/extract dev/);

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

sub route_check {
    my %args = @_;

    my $home_url = $args{"home_url"};
    my $route    = $args{"route"} // "";
    my $fail     = $args{"fail"} // 0;
    my $bbox     = $args{"bbox"};
    my $padding  = $args{"padding"};
    my $distance = $args{"distance"};

    my $script_url = URI->new("$home_url/cgi/route.cgi");
    my %query_form;
    $query_form{"route"} = $route if $route ne "";
    $query_form{"padding"} = $padding if $route ne "" && defined $padding;

    foreach my $arg (qw/email format appid ref/) {
        $query_form{$arg} = $args{$arg} if defined $args{$arg};
    }

    $script_url->query_form(%query_form);

    my $res      = $test->myget_302($script_url);
    my $location = $res->header("Location");

    diag "location: $location $script_url" if $debug >= 1;

    my $uri   = URI->new($location);
    my $query = $uri->query;

    my $q = CGI->new($query);
    if ( !$fail ) {
        is( $q->param("email"), $args{"email"} // "nobody", "default email" );
        is(
            $q->param("format"),
            $args{"format"} // "garmin-cycle-latin1.zip",
            "default format"
        );
        is( $q->param("appid"), $args{"appid"} // "gpsies1", "default appid " );
        is( $q->param("ref"), $args{"ref"} // "gpsies.com", "default ref" );
    }

    like(
        $location,
        qr[https://extract[0-9]?\.bbbike\.org\?.*appid=.+],
        "redirect to extract.cgi: $script_url"
    );
    if ($fail) {

        # check for error parameter
        like(
            $location,
            qr[https://extract[0-9]?\.bbbike\.org\?.*error=],
            "redirect to extract.cgi: $script_url"
        );
    }
    else {

        # check for error parameter
        unlike(
            $location,
            qr[https://extract[0-9]?\.bbbike\.org\?.*error=],
            "redirect to extract.cgi: $script_url"
        );
    }

# validate bbox from redirect URL
# https://extract.bbbike.org?ne_lng=12.91614&ne_lat=50.67381&sw_lng=12.62077&sw_lat=50.45206&format=garmin-cycle-latin1.zip&city=gpsies+map&appid=gpsies1&ref=gpsies.com&email=nobody
    if ( $bbox && !$fail ) {
        my $uri = URI->new($location);
        ok($uri);

        my $q = CGI->new( $uri->query );
        ok($q);

        is( $q->param("ne_lng"), $bbox->{"ne_lng"},
            "validate ne_lng parameter" );
        is( $q->param("ne_lat"), $bbox->{"ne_lat"},
            "validate ne_lat parameter" );
        is( $q->param("sw_lng"), $bbox->{"sw_lng"},
            "validate sw_lng parameter" );
        is( $q->param("sw_lat"), $bbox->{"sw_lat"},
            "validate sw_lat parameter" );

        # check other parameters as well
        ok( defined $q->param("appid"),  "appid is set" );
        ok( defined $q->param("ref"),    "ref is set" );
        ok( defined $q->param("email"),  "email is set" );
        ok( defined $q->param("appid"),  "appid is set" );
        ok( defined $q->param("format"), "format is set" );

        # compare distance in rounded integers
        if ( defined $distance ) {
            my @b = (
                scalar $q->param("sw_lng"),
                scalar $q->param("sw_lat"),
                scalar $q->param("ne_lng"),
                scalar $q->param("ne_lat")
            );
            my $d = GIS::Distance::Lite::distance(@b) / 1000;
            is( int($d), $distance, "test distance=$distance" );
        }
    }
}

#############################################################################
# main
#

my $bbox = [ 10.92079, 51.83964, 10.7935, 51.78166 ];
my $distance = GIS::Distance::Lite::distance(@$bbox) / 1000;
is( $distance, 15.507231100269823, "test distance" );

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{

    # local cache
    &route_check( "home_url" => $home_url );

    # "bbox": [10.92079, 51.83964, 10.7935, 51.78166]
    # no padding
    &route_check(
        "home_url" => $home_url,
        "route"    => "fjurfvdctnlcmqtu",
        "bbox"     => {
            "ne_lng" => 10.92079,
            "ne_lat" => 51.83964,
            "sw_lng" => 10.7935,
            "sw_lat" => 51.78166
        },
        "padding"  => 0,
        "distance" => 15,
    );

    # check format parameters etc.
    &route_check(
        "home_url" => $home_url,
        "route"    => "fjurfvdctnlcmqtu",
        "bbox"     => {
            "ne_lng" => 10.92079,
            "ne_lat" => 51.83964,
            "sw_lng" => 10.7935,
            "sw_lat" => 51.78166
        },
        "padding"  => 0,
        "distance" => 15,

        "format" => "garmin-cycle.zip",
        "email"  => q[nobody@bbbike.org],
        "appid"  => "gpsies1",
        "ref"    => "ref",
        "route"  => "fjurfvdctnlcmqtu"
    );

    # check format parameters etc.
    &route_check(
        "home_url" => $home_url,
        "route"    => "fjurfvdctnlcmqtu",
        "bbox"     => {
            "ne_lng" => 10.92079,
            "ne_lat" => 51.83964,
            "sw_lng" => 10.7935,
            "sw_lat" => 51.78166
        },
        "padding"  => 0,
        "distance" => 15,

        "format" => "",
        "email"  => "",
        "appid"  => "",
        "ref"    => "",
    );

    # padding 20km around the bbox
    &route_check(
        "home_url" => $home_url,
        "route"    => "fjurfvdctnlcmqtu",
        "bbox"     => {
            "ne_lng" => 11.12079,
            "ne_lat" => 52.03964,
            "sw_lng" => 10.5935,
            "sw_lat" => 51.58166
        },
        "padding"  => 20,
        "distance" => 77,
    );

    # no padding parameter, defaults to 10
    &route_check(
        "home_url" => $home_url,
        "route"    => "fjurfvdctnlcmqtu",
        "bbox"     => {
            "ne_lng" => 11.02079,
            "ne_lat" => 51.93964,
            "sw_lng" => 10.6935,
            "sw_lat" => 51.68166
        },
        "distance" => 46,
    );

    # fake route id, to long
    &route_check(
        "home_url" => $home_url,
        "route"    => "XXXfjurfvdctnlcmqtu",
        "fail"     => 1
    );

    # fake route id, wrong characters
    &route_check(
        "home_url" => $home_url,
        "route"    => "Fjurfvdctnlcmqtu",
        "fail"     => 1
    );

    # to short id
    &route_check( "home_url" => $home_url, "route" => "XXX", "fail" => 1 );

    # web fetch
    &route_check( "home_url" => $home_url, "route" => "uuwfflkzmvudvzgs" );

    # "bbox": [12.91614, 50.67381, 12.62077, 50.45206]
    &route_check(
        "home_url" => $home_url,
        "route"    => "uuwfflkzmvudvzgs",
        "bbox"     => {
            "ne_lng" => 12.91614,
            "ne_lat" => 50.67381,
            "sw_lng" => 12.62077,
            "sw_lat" => 50.45206
        },
        "padding"  => 0,
        "distance" => 40,
    );
}

done_testing;

