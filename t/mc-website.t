#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org
#
# check map compare JS/images and external libs
#

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Encode;
use Test::More;
use BBBike::Test;

my $test = BBBike::Test->new();

our $enable_devel_server = 1;    # y.tile.bbbike.org

my @list = (
    {
        'page' =>
'https://maps.googleapis.com/maps/api/js?v=3.9&sensor=false&language=en&libraries=weather',
        'min_size'  => 1_000,
        'match'     => [],
        'mime_type' => 'text/javascript'
    },
);

my @javascript = qw(
  https://mc.bbbike.org/mc/js/OpenLayers/2.12/OpenLayers.min.js
  https://mc.bbbike.org/mc/js/OpenLayers/2.12/OpenStreetMap.js
  https://mc.bbbike.org/mc/js/OpenLayers/2.12/Here.js
  https://mc.bbbike.org/mc/js/jqModal/jqModal-1.1.0.js
  https://mc.bbbike.org/mc/js/jquery/jquery-1.8.3.min.js
  https://mc.bbbike.org/mc/js/jquery/jquery-ui-1.7.2.custom.min.js
  https://mc.bbbike.org/mc/js/jquery/jquery.cookie.js
  https://mc.bbbike.org/mc/js/jquery/jquery.iecors.js
  https://mc.bbbike.org/mc/js/mc.js
);

my @gif = qw(
  https://mc.bbbike.org/mc/img/bg-right.gif
  https://mc.bbbike.org/mc/img/help.gif
  https://mc.bbbike.org/mc/img/close.gif
  https://mc.bbbike.org/mc/img/indicator.gif
);

my @png = qw(
  https://mc.bbbike.org/mc/img/bg-bottom.png
  https://mc.bbbike.org/mc/img/bg-top.png
  https://mc.bbbike.org/mc/img/cross.png
  https://mc.bbbike.org/mc/img/location-icon.png
  https://mc.bbbike.org/mc/img/social/rss-icon.png
  https://mc.bbbike.org/mc/img/social/twitter-t.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/east-mini.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/north-mini.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/slider.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/south-mini.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/west-mini.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/zoom-minus-mini.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/zoom-plus-mini.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/zoombar.png
  https://mc.bbbike.org/mc/img/theme/geofabrik/img/cloud-popup-relative.png
);

my @css = qw(
  https://mc.bbbike.org/mc/css/common.css
  https://mc.bbbike.org/mc/css/mc.css
  https://mc.bbbike.org/mc/css/OpenLayers/style.css
);

my @html = qw(
  https://mc.bbbike.org/mc/
);

foreach my $item (@png) {
    push @list,
      {
        'page'      => $item,
        'min_size'  => 200,
        'match'     => [],
        'mime_type' => 'image/png'
      };
}

foreach my $item (@gif) {
    push @list,
      {
        'page'      => $item,
        'min_size'  => 200,
        'match'     => [],
        'mime_type' => 'image/gif'
      };
}

foreach my $item (@html) {
    push @list,
      {
        'page'      => $item,
        'min_size'  => 2_000,
        'match'     => [ '</html>', '<head>', '<body>' ],
        'mime_type' => 'text/html'
      };
}

foreach my $item (@css) {
    push @list,
      {
        'page'      => $item,
        'min_size'  => 1_500,
        'match'     => [ 'top:', 'border:', 'font-size:' ],
        'mime_type' => 'text/css'
      };
}

foreach my $item (@javascript) {
    push @list,
      {
        'page'      => $item,
        'min_size'  => 1_500,
        'match'     => [],
        'mime_type' => 'application/javascript'
      };
}

my $count = 3 * scalar(@list);
foreach my $obj (@list) {
    $count += scalar( @{ $obj->{'match'} } );
}

#
# both production and devel server:
# https://mc.bbbike.org
# https://y.tile.bbbike.org
#
if ($enable_devel_server) {
    push @list, map { s,mc.bbbike.org,y.tile.bbbike.org,; $_ } @list;
    $count *= 2;
}

plan tests => $count;

############################################################################
my $ua = $test->{'ua'};

foreach my $obj (@list) {
    my $url = $obj->{'page'};

    $url =~ s,^http:,https:,;

    my $resp = $ua->get($url);
    ok( $resp->is_success, $url );

    my $mime_type = exists $obj->{mime_type} ? $obj->{mime_type} : "text/html";
    is( $resp->content_type, $mime_type, "page $url is $mime_type" );

    my $content = $resp->decoded_content;
    my $length =
      defined $resp->content_length ? $resp->content_length : length($content);
    cmp_ok( $length, ">", $obj->{min_size},
        "page $url is greather than: " . $length . " > " . $obj->{min_size} );

    next if !exists $obj->{'match'};
    foreach my $match ( @{ $obj->{'match'} } ) {
        like $content, qr{$match}, qq{Found string '$match'};
    }
}

__END__
