#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Poly;
use Extract::Planet;
use BBBike::WorldDB;

use strict;
use warnings;

my $debug   = 1;
my $poly    = new Extract::Poly( 'debug' => $debug );
my $planet  = new Extract::Planet( 'debug' => $debug );
my @regions = $poly->list_subplanets;

my $planet_polygon = &planet_polygon;
cmp_ok( scalar(@$planet_polygon),
    ">=", 5, "polygon points: planet: @{[ scalar(@$planet_polygon) ]}" );

#######################################################################################
# check for valid inner polygons
#

sub planet_polygon {
    $Extract::Poly::area->{'planet'}->{"poly"} =
      $Extract::Poly::area->{'planet'}->{"poly2"};

    my $obj = $poly->get_job_obj('planet');
    my ( $data, $counter, $polygon ) = $poly->create_poly_data( 'job' => $obj );

    return $polygon;
}

sub get_polygon {
    my $name = shift;
    my $list = shift;

    my $obj = $poly->get_job_obj( $name, $list );
    my ( $data, $counter, $polygon ) = $poly->create_poly_data( 'job' => $obj );
    return $polygon;
}

sub check_regions {
    my @regions = @_;
    foreach my $region (@regions) {
        my $obj = $poly->get_job_obj($region);
        my ( $data, $counter, $polygon ) =
          $poly->create_poly_data( 'job' => $obj );

        cmp_ok( scalar(@$polygon), ">=", 5,
            "polygon points: $region: @{[ scalar(@$polygon) ]}" );

        my $inner = $planet->sub_polygon(
            'inner' => $polygon,
            'outer' => $planet_polygon
        );
        is( $inner, 1, "region $region is inside planet" );
    }

    return 2 * scalar(@regions);
}

sub check_cities {
    my $obj    = $poly->get_job_obj('central-europe');
    my $region = 'Berlin';

    my $berlin_polygon = get_polygon( $region, [ 12.76, 52.23, 13.98, 52.82 ] );
    my $inner = $planet->sub_polygon(
        'inner' => $berlin_polygon,
        'outer' => $planet_polygon
    );
    is( $inner, 1, "region $region is inside planet" );

    my $outer = 'central-europe';
    $inner = $planet->sub_polygon(
        'inner' => $berlin_polygon,
        'outer' => get_polygon($outer)
    );
    is( $inner, 1, "region $region is inside $outer" );

    $outer = 'europe';
    $inner = $planet->sub_polygon(
        'inner' => $berlin_polygon,
        'outer' => get_polygon($outer)
    );
    is( $inner, 1, "region $region is inside $outer" );

    $outer = 'asia';
    $inner = $planet->sub_polygon(
        'inner' => $berlin_polygon,
        'outer' => get_polygon($outer)
    );
    is( $inner, 0, "region $region is outside $outer" );

    return 4;
}

sub check_bbbike_cities {

    my $database = "world/etc/cities.csv";
    my $db      = BBBike::WorldDB->new( 'database' => $database, 'debug' => 0 );
    my %hash    = %{ $db->city };
    my $counter = 0;

    diag Dumper( \%hash ) if $debug >= 3;

    foreach my $city ( keys %hash ) {
        my $area  = $hash{$city}->{"area"};
        my $coord = $hash{$city}->{"coord"};
        my @coord = split( /\s+/, $coord );

        my $city_polygon = get_polygon( $city, \@coord );
        my $inner = $planet->sub_polygon(
            'inner' => $city_polygon,
            'outer' => $planet_polygon
        );
        is( $inner, 1, "region $city is inside planet" );

        #my $outer = 'central-europe';
        #$inner = $planet->sub_polygon(
        #    'inner' => $city_polygon,
        #    'outer' => get_polygon($outer)
        #);
        #my $result = $area eq 'de' ? 1 : 0;
        #is( $inner, $result, "region $city is inside $outer" );

        my $result = $area =~ /^(de|eu)$/ ? 1 : 0;
        my $outer = 'europe';
        $inner = $planet->sub_polygon(
            'inner' => $city_polygon,
            'outer' => get_polygon($outer)
        );
        is( $inner, $result, "region $city is inside $outer" );

        $counter += 3;
    }

    return $counter;
}

my $counter = 1;
$counter += &check_regions(@regions);
$counter += &check_cities;
$counter += &check_bbbike_cities;

plan tests => $counter;
__END__
