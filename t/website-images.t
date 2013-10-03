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
  qw[ http://www.bbbike.org http://dev2.bbbike.org http://dev4.bbbike.org http://extract.bbbike.org http://extract2.bbbike.org];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

use constant MYGET => 3;
my @images =
  qw/mm_20_yellow.png srtbike72.png srtbike114.png srtbike57.png shadow-dot.png dest.gif purple-dot.png mm_20_white.png ubahn.gif mm_20_red.png sbahn.gif printer.gif printer_narrow.gif ziel.gif mm_20_green.png yellow-dot.png dd-end.png dd-start.png phone.png via.gif start.gif twitter-t.png spinning_wheel32.gif srtbike.gif srtbike1.ico rss-icon.png google-plusone-t.png flattr-compact.png facebook-like.png twitter-b.png donate.png facebook-t.png/;

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
    &images($hp);
}

__END__

