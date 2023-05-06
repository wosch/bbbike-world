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

    print "1..0 # not done yet\n";
    exit 0;
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use Test::More::UTF8;
use BBBike::Test;
use Extract::Config;

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list(qw/extract dev/);

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my @lang = qw/en de fr/;    # ru, es
my @tags = (
    '</html>',   '<head>',
    '<body[ >]', '</body>',
    '</head>',   '<html[ >]',
    '<div id="footer_top">'
);

my $msg = {
    "en" =>
      [ "Thanks - the input data looks good", "We appreciate any feedback" ],
    "de" => [
        "Danke - die Eingabedaten sind korrekt",
        "Du kannst uns via PayPal oder Banküberweisung unterstützen"
    ],
    "fr" => [
        "Merci - les paramètres saisis semblent corrects",
        "Nous apprécions tous les commentaires"
    ],

    # rest
    "XYZ" =>
      [ "Thanks - the input data looks good", "We appreciate any feedback" ],
    "" =>
      [ "Thanks - the input data looks good", "We appreciate any feedback" ],
};

my $submit_path = {
    'path' =>
'/cgi/extract.cgi?sw_lng=-72.211&sw_lat=-13.807337108&ne_lng=-71.732&ne_lat=-13.235565653&email=Nobody&as=1.933243109431466&pg=0.9964839602712444&coords=&oi=1&city=София%2C%20Ингилизка%20махала%2C%20Pernik%2C%20Pernik&submit=extract&format=osm.pbf',
    'match' => [qr/value="София, Ингилизка махала, Pernik/]
};

sub page_check_unicode {
    my ( $home_url, $submit_path ) = @_;

    foreach my $obj (@$unicode) {
        my $path  = $obj->{'path'};
        my $match = $obj->{'match'};
        my $url   = $home_url . $path;

        my $res = $test->myget( $url, 3_900 );

        foreach my $text (@$match) {
            like( $res->decoded_content, $text, "match unicode: $text $url" );
        }
    }
}

sub page_check {
    my $home_url = shift;

    my $path = $submit_path->{'path'};
    my $script_url = shift || "$home_url$path";

    if ( !$ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        my $res = $test->myget( "$script_url", 10_000 );
        like( $res->decoded_content, qr|id="map"|,           "bbbike extract" );
        like( $res->decoded_content, qr|polygon_update|,     "bbbike extract" );
        like( $res->decoded_content, qr|"garmin-cycle.zip"|, "bbbike extract" );
        like( $res->decoded_content, qr| content="text/html; charset=utf-8"|,
            "charset" );
        like( $res->decoded_content, qr| http-equiv="Content-Type"|,
            "Content-Type" );

        foreach my $tag (@tags) {
            like( $res->decoded_content, qr|$tag|,
                "bbbike extract html tag: $tag url:$script_url" );
        }

        like( $res->decoded_content, qr|polygon_update|, "bbbike extract" );

    }
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{

    diag "checked site: $home_url";
    &page_check($home_url);

    #&page_check_unicode( $home_url, $submit_path );
}

done_testing;

__END__
