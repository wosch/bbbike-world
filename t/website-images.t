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

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://www.bbbike.org http://dev1.bbbike.org http://dev4.bbbike.org http://extract.bbbike.org http://extract1.bbbike.org];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

use constant MYGET => 3;
my @images =
  qw/mm_20_yellow.png srtbike72.png srtbike114.png srtbike57.png shadow-dot.png
  dest.gif purple-dot.png mm_20_white.png ubahn.gif mm_20_red.png sbahn.gif
  printer.gif printer_narrow.gif ziel.gif mm_20_green.png yellow-dot.png
  dd-end.png dd-start.png phone.png via.gif start.gif twitter-t.png spinning_wheel32.gif
  srtbike.gif srtbike1.ico rss-icon.png google-plusone-t.png flattr-compact.png
  facebook-like.png twitter-b.png donate.png facebook-t.png/;

my @screenshot_images =
  qw/garmin-bbbike-small.png garmin-cycle5-small.png garmin-mallorca-3000.png
  garmin-srtm-2000.png garmin-bbbike2-micro.png garmin-leisure-micro.png garmin-mallorca-500.png
  garmin-srtm-300.png garmin-bbbike2-small.png garmin-leisure-small.png garmin-mallorca-800.png
  garmin-srtm-3000.png garmin-bbbike3-small.png garmin-leisure2-micro.png garmin-osm-micro.png
  garmin-srtm-500.png garmin-bbbike4-small.png garmin-leisure2-small.png garmin-osm-small.png garmin-srtm-80.png
  garmin-bbbike5-small.png garmin-leisure3-small.png garmin-osm2-micro.png garmin-srtm-800.png
  garmin-cycle-micro.png garmin-leisure4-small.png garmin-osm2-small.png navit-micro.png
  garmin-cycle-small.png garmin-leisure5-small.png garmin-osm3-small.png navit-small.png
  garmin-cycle2-micro.png garmin-mallorca-120.png garmin-osm4-small.png navit-tiny.png
  garmin-cycle2-small.png garmin-mallorca-200.png garmin-osm5-small.png osmand-micro.png
  garmin-cycle3-small.png garmin-mallorca-2000.png garmin-srtm-1200.png osmand-small.png
  garmin-cycle4-small.png garmin-mallorca-300.png garmin-srtm-200.png osmand-tiny.png/;

push @images, @screenshot_images;

plan tests => @images * ( MYGET + 1 ) * scalar(@homepages);

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

sub images {
    my $homepage = shift;

    foreach my $image (@images) {
        my $res = myget( "$homepage/images/$image", 60 );
        my $mime_type = "image/"
          . (
              $image =~ /\.gif$/ ? "gif"
            : $image =~ /\.ico$/ ? "x-icon"
            : "png"
          );
        is( $res->content_type, $mime_type, "$image is $mime_type" );
    }
}

foreach my $hp (@homepages) {
    diag "test homepage $hp";
    &images($hp);
}

__END__

