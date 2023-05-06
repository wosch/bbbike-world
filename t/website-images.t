#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use BBBike::Test;
use Extract::Config;

use strict;
use warnings;

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my $homepage = 'https://www.bbbike.org';

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list(qw/www extract dev/);

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my @images =
  qw/mm_20_yellow.png srtbike72.png srtbike114.png srtbike57.png shadow-dot.png
  dest.gif purple-dot.png mm_20_white.png ubahn.gif mm_20_red.png sbahn.gif
  printer.gif printer_narrow.gif ziel.gif mm_20_green.png yellow-dot.png
  dd-end.png dd-start.png phone.png via.gif start.gif twitter-t.png spinning_wheel32.gif
  srtbike.gif srtbike1.ico rss-icon.png
  twitter-b.png donate.png/;

my @screenshot_images =
  qw/garmin-bbbike-small.png garmin-cycle5-small.png garmin-mallorca-3000.png
  garmin-srtm-2000.png garmin-bbbike2-micro.png garmin-leisure-micro.png garmin-mallorca-500.png
  garmin-srtm-300.png garmin-bbbike2-small.png garmin-leisure-small.png garmin-mallorca-800.png
  garmin-srtm-3000.png garmin-bbbike3-small.png garmin-leisure2-micro.png garmin-osm-micro.png
  garmin-srtm-500.png garmin-bbbike4-small.png garmin-leisure2-small.png garmin-osm-small.png garmin-srtm-80.png
  garmin-bbbike5-small.png garmin-leisure3-small.png garmin-osm2-micro.png garmin-srtm-800.png
  garmin-cycle-micro.png garmin-leisure4-small.png garmin-osm2-small.png
  garmin-cycle-small.png garmin-leisure5-small.png garmin-osm3-small.png
  garmin-cycle2-micro.png garmin-mallorca-120.png garmin-osm4-small.png
  garmin-cycle2-small.png garmin-mallorca-200.png garmin-osm5-small.png osmand-micro.png
  garmin-cycle3-small.png garmin-mallorca-2000.png garmin-srtm-1200.png osmand-small.png
  garmin-cycle4-small.png garmin-mallorca-300.png garmin-srtm-200.png osmand-tiny.png
  osmand-small.png osmand-tiny.png
  /;

push @images, @screenshot_images;

plan tests => @images * ( $test->myget_counter + 1 ) * scalar(@homepages);

sub images {
    my $homepage = shift;

    foreach my $image (@images) {
        my $res = $test->myget( "$homepage/images/$image", 60 );
        my $mime_type = "^image/"
          . (
              $image =~ /\.gif$/ ? "gif"
            : $image =~ /\.ico$/ ? "(x-icon|vnd.microsoft.icon)"
            :                      "png"
          ) . '$';
        like( $res->content_type, qr[$mime_type], "$image is $mime_type" );
    }
}

foreach my $hp (@homepages) {
    diag "test homepage $hp";
    &images($hp);
}

__END__

