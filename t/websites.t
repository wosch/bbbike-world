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

use utf8;    # test contains unicode characters, see Test::More::UTF8;
use Encode;
use Test::More;

use Test::More::UTF8;
use BBBike::Test;

use strict;
use warnings;

my $test = BBBike::Test->new();

my @cities = qw/Berlin Cottbus Toronto/;

# unicode cities
my @cities_utf8 = (
    "Київ",                                "‏بيروت",
    "กรุงเทพมหานคร", "Thành phố Hồ Chí Minh",
    "София"
);

my @list = (
    {
        'page'     => 'https://www.bbbike.org',
        'min_size' => 10_000,
        'match'    => [ "</html>", @cities, @cities_utf8 ]
    },
    {
        'page'     => 'https://m.bbbike.org',
        'min_size' => 1_000,
        'match'    => [ "</html>", @cities ]
    },
    {
        'page'     => 'https://www.bbbike.org/en/',
        'min_size' => 10_000,
        'match'    => [ "</html>", @cities ]
    },
    {
        'page'     => 'https://www.bbbike.org/de/',
        'min_size' => 10_000,
        'match'    => [ "</html>", @cities ]
    },
    {
        'page'     => 'https://extract.bbbike.org',
        'min_size' => 5_000,
        'match'    => [ "</html>", "about" ]
    },
    {
        'page'     => 'https://download.bbbike.org/osm/',
        'min_size' => 2_000,
        'match' => [ "</html>", "Select your own region", "For experts only" ]
    },
    {
        'page'     => 'https://mc.bbbike.org/osm/',
        'min_size' => 1_500,
        'match'    => [ "</html>", qq/ id="map">/ ]
    },
    {
        'page'     => 'https://mc.bbbike.org/mc/',
        'min_size' => 5_000,
        'match' =>
          [ "</html>", "Choose map type", ' src="js/mc.js(\?version=\d+)?"' ]
    },
    {
        'page'     => 'https://a.tile.bbbike.org/osm/bbbike/15/17602/10746.png',
        'min_size' => 10_000,
        'match'    => [],
        'mime_type' => 'image/png'
    },
);

my $count = 3 * scalar(@list);
foreach my $obj (@list) {
    $count += scalar( @{ $obj->{'match'} } );
}

plan tests => $count;

my $ua = $test->{'ua'};

foreach my $obj (@list) {
    my $url = $obj->{'page'};

    my $resp = $ua->get($url);
    ok( $resp->is_success, $url );

    my $mime_type = exists $obj->{mime_type} ? $obj->{mime_type} : "text/html";
    is( $resp->content_type, $mime_type, "page $url is $mime_type" );
    my $content = $resp->decoded_content;
    my $content_length =
      defined $resp->content_length ? $resp->content_length : length($content);

    cmp_ok( $content_length, ">", $obj->{min_size},
            "page $url is greather than: "
          . $content_length . " > "
          . $obj->{min_size} );

    next if !exists $obj->{'match'};
    foreach my $match ( @{ $obj->{'match'} } ) {
        like $content, qr{$match}, qq{Found string '$match'};
    }
}

__END__
