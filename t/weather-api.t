#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2014 Wolfram Schneider, http://bbbike.org

use Test::More;
use JSON;
use LWP;
use LWP::UserAgent;
use Data::Dumper;

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

my $debug = 1;

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://www.bbbike.org http://www2.bbbike.org http://dev1.bbbike.org http://dev2.bbbike.org ];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

use constant MYGET     => 3;
use constant API_CHECK => 4;
use constant LANG      => 2;

#plan 'no_plan';
plan tests => scalar(@homepages) * LANG * ( API_CHECK + MYGET );

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget {
    my $url  = shift;
    my $size = shift;

    $size = 168 if !defined $size;

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200" );

    my $content = $res->decoded_content();
    cmp_ok( length($content), ">", $size, "greather than $size for URL $url" );

    return $res;
}

sub api_check {
    my $url = shift;

    my $res = myget( "$url", 168 );
    my $perl = decode_json( $res->decoded_content );

    is($res->content_type, "application/json", "application/json");
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
