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

    my $script_url = "$home_url/cgi/route.cgi";

    if ( $route ne "" ) {
        $script_url .= "?route=" . $route;
    }

    my $res      = $test->myget_302($script_url);
    my $location = $res->header("Location");

    diag "location: $location $script_url" if $debug >= 1;

    my $command = $fail ? "unlike" : "like";
    {
        no strict 'refs';

        &$command(
            $location,
            qr[https://extract[0-9]?\.bbbike\.org\?],
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
        ok( $q->param("appid"),  "appid is set" );
        ok( $q->param("ref"),    "ref is set" );
        ok( $q->param("email"),  "email is set" );
        ok( $q->param("appid"),  "appid is set" );
        ok( $q->param("format"), "format is set" );
    }
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{
    # local cache
    &route_check( "home_url" => $home_url );

    # "bbox": [10.92079, 51.83964, 10.7935, 51.78166]
    &route_check(
        "home_url" => $home_url,
        "route"    => "fjurfvdctnlcmqtu",
        "bbox"     => {
            "ne_lng" => 10.92079,
            "ne_lat" => 51.83964,
            "sw_lng" => 10.7935,
            "sw_lat" => 51.78166
        }
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
        }
    );
}

done_testing;

