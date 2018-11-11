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

use URI;
use URI::QueryParam;
use Test::More;
use JSON;
use BBBike::Test;
use Extract::Config;
use Extract::TileSize;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list( 'extract', 'dev' );

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my $formats          = $Extract::Config::formats;
my $factor_tile_size = $Extract::TileSize::factor;

plan 'no_plan';

# check the formats configuration in lib/Extract/TileSize.pm
sub factor_check {
    my %hash;
    my $factor = $factor_tile_size;

    foreach my $f ( keys %$factor ) {

        # basic planet factor types
        next if grep { $_ eq $f } qw/pbf srtm-pbf srtm-europe-pbf/;

        cmp_ok( $factor->{$f}, '!=', 1,
            "format $f should not have size of $factor->{$f}" );

        isnt(
            $factor->{$f},
            $hash{ $factor->{$f} },
            "format $f should not have size of $hash{$factor->{$f}}"
        );
        $hash{ $factor->{$f} } = $f;
    }
}

sub page_check {
    my $home_url   = shift;
    my $script_url = shift
      || "$home_url/cgi/tile-size.cgi?lat_sw=51.775&lng_sw=11.995&lat_ne=53.218&lng_ne=14.775";

    my %size;
    foreach my $f ( keys %$formats ) {
        my $uri = URI->new($script_url);
        $uri->query_param( "format", $f );

        my $res = $test->myget( $uri->as_string, 11 );

        # {"size": 65667.599 }
        # {"size": 0 }

        my $obj = from_json( $res->decoded_content );
        like( $obj->{"size"}, qr/^[\d\.]+$/,
            "format: $f, size: $obj->{'size'} url: $url" );

        # no two formats should have the same size
        # otherwise we may have forgotten to configure a format
        is(
            $size{ $obj->{'size'} },
            undef,
"format: $f match size $obj->{'size'} of $size{$obj->{'size'}}, did you forgot to configure format $f? url: $url"
        );

        $size{ $obj->{'size'} } = $f;
    }
}

sub planet_file_is_available {
    my $planet_osm = $Extract::Config::planet_osm;

    foreach my $planet ( keys %$planet_osm ) {
        my $file = $planet_osm->{$planet};
        if ( !-r $file ) {
            diag
              "planet file '$planet' -> '$file' does not exists, skip tests\n";
            return 0;
        }
    }

    return 1;
}

#############################################################################
# main
#

&factor_check;

if (&planet_file_is_available) {

    # check a bunch of homepages
    foreach my $home_url (
        $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
    {
        &page_check($home_url);
    }
}

__END__
