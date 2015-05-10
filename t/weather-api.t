#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
}

use Test::More;
use Data::Dumper;
use JSON;
use lib qw(./world/lib ../lib);
use BBBike::Test;

use strict;
use warnings;

my $test  = BBBike::Test->new();
my $debug = 1;

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://www.bbbike.org http://www2.bbbike.org http://dev1.bbbike.org http://dev2.bbbike.org ];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

use constant API_CHECK => 4;
use constant LANG      => 2;

#plan 'no_plan';
plan tests => scalar(@homepages) * LANG * ( API_CHECK + $test->myget_counter );

sub api_check {
    my $url = shift;

    my $res = $test->myget( "$url", 168 );
    my $perl = decode_json( $res->decoded_content );

    is( $res->content_type, "application/json", "application/json" );

    #is($res->charset, "charset=utf-8", "charset=utf-8");

    isnt( $perl->{'weather'}, undef, "weather object" );
    isnt( $perl->{'weather'}->{'weatherObservation'}->{'temperature'},
        undef, "weather temperature" );
    isnt( $perl->{'weather'}->{'weatherObservation'}->{'windSpeed'},
        undef, "weather windSpeed" );

    warn Dumper($perl) if $debug >= 2;
}

#############################################################################
# main
#

my $url_path =
'cgi/weather.cgi?lat=48.77849&lng=9.18004&city=Stuttgart&city_script=Stuttgart';

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{
    &api_check("$home_url/$url_path&lang=de");
    &api_check("$home_url/$url_path&lang=en");
}

__END__
