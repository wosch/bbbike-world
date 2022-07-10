#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

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

use Test::More;
use BBBike::Test;

my $test = BBBike::Test->new();

my $homepage = 'https://www.bbbike.org';
my @cities   = qw/Berlin Zuerich Toronto Moscow/;
my @images =
  qw/mm_20_yellow.png srtbike72.png srtbike114.png srtbike57.png shadow-dot.png dest.gif purple-dot.png mm_20_white.png ubahn.gif mm_20_red.png sbahn.gif printer.gif printer_narrow.gif ziel.gif mm_20_green.png yellow-dot.png dd-end.png dd-start.png phone.png px_1t.gif via.gif start.gif twitter-t.png spinning_wheel32.gif srtbike.gif srtbike1.ico rss-icon.png twitter-b.png donate.png/;

if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    plan tests => scalar(@cities) * $test->myget_counter * 4 +
      $test->myget_counter * 11;
}
else {
    plan 'no_plan';
}

foreach my $city (@cities) {
    my $url = "$homepage/$city/";
    my $res = $test->myget($url);

    # skip other tests on slow networks (e.g. on mobile phone links)
    next if $ENV{BBBIKE_TEST_SLOW_NETWORK};

    $url = "$homepage/en/$city/";
    $test->myget($url);
    $url = "$homepage/ru/$city/";
    $test->myget($url);
    $url = "$homepage/de/$city/";

    $test->myget( "$homepage/osp/$city.xml", 100 );
}

$test->myget( "$homepage/osp/Zuerich.en.xml", 100 );
$test->myget( "$homepage/osp/Toronto.de.xml", 100 );
$test->myget( "$homepage/osp/Moscow.de.xml",  100 );
$test->myget( "$homepage/osp/Moscow.en.xml",  100 );

$test->myget( "$homepage/html/bbbike.css", 7_000 );
$test->myget( "$homepage/html/devbridge-jquery-autocomplete-1.1.2/shadow.png",
    1_000 );

if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    $test->myget( "$homepage/html/bbbike-js.js", 100_000 );
    $test->myget( "$homepage/html/streets.css",  2_000 );
    $test->myget( "$homepage/html/luft.css",     3_000 );
    $test->myget(
"$homepage/html/devbridge-jquery-autocomplete-1.1.2/jquery.autocomplete-min.js",
        1_000
    );
    $test->myget( "$homepage/html/jquery/jquery-1.4.2.min.js", 20_000 );
}

__END__
foreach my $image (@images) {
   my $res = $test->myget("$homepage/images/$image");
   my $image = "image/png";
   is( $res->content_type, $mime_type, "$image is $mime_type" );
}

