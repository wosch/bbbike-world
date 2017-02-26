#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, https://bbbike.org

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Poly;
use Extract::Planet;
use BBBike::WorldDB;

use strict;
use warnings;

my $debug          = 1;
my $poly           = new Extract::Poly( 'debug' => $debug );
my $planet         = new Extract::Planet( 'debug' => $debug );
my @regions        = $poly->list_subplanets;
my @regions_sorted = $poly->list_subplanets( 'sort_by' => 1 );

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
    my @close_eu = qw/Baghdad Istanbul Jerusalem Beirut Alexandria Cairo/;

    foreach my $city ( keys %hash ) {
        next if $hash{$city}->{"dummy"};

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

        my $result =
          $area =~ /^(de|eu)$/ ? 1 : scalar( grep { $city eq $_ } @close_eu );

        my $outer = 'europe';
        $inner = $planet->sub_polygon(
            'inner' => $city_polygon,
            'outer' => get_polygon($outer)
        );
        is( $inner, $result, "region $city is inside $outer" );
        $counter += 2;

        # European cities are outside of nothern america
        next if $area !~ /^(de|eu)$/;

        $outer  = 'north-america';
        $result = 0;
        $inner  = $planet->sub_polygon(
            'inner' => $city_polygon,
            'outer' => get_polygon($outer)
        );
        is( $inner, $result, "region $city is inside $outer" );

        $counter += 1;
    }

    return $counter;
}

sub check_match_cities {
    my $database = "world/etc/cities.csv";
    my $db      = BBBike::WorldDB->new( 'database' => $database, 'debug' => 0 );
    my %hash    = %{ $db->city };
    my $counter = 0;

    diag Dumper( \%hash )           if $debug >= 3;
    diag Dumper( \@regions_sorted ) if $debug >= 2;

    # avoid perl warnings
    sub get_part {
        my $city = shift;
        my $name = shift;

        no warnings;
        return $hash{$city}->{$name};
    }

    sub check_sorted_regions {
        my $sub_planet = shift;
        my @cities     = @_;

        my $counter = 0;

        foreach my $city (@cities) {
            get_part("area");

            my $area  = get_part( $city, "area" );
            my $coord = get_part( $city, "coord" );
            my @coord = split( /\s+/, $coord );

            my $city_polygon = get_polygon( $city, \@coord );

            foreach my $outer (@regions_sorted) {
                my $result = $outer eq $sub_planet ? 1 : 0;

                my $inner = $planet->sub_polygon(
                    'inner' => $city_polygon,
                    'outer' => get_polygon($outer)
                );
                is( $inner, $result,
                    "region $city is inside $sub_planet, but got $outer" );
                $counter += 1;

                # stop at first match
                last if $result == 1;
            }
        }

        return $counter;
    }

    $counter +=
      &check_sorted_regions( 'germany-europe', qw/Berlin Hamburg Dresden/ );
    $counter += &check_sorted_regions( 'central-europe', qw/Amsterdam/ );
    $counter += &check_sorted_regions( 'europe', qw/London Madrid Sofia/ );
    $counter +=
      &check_sorted_regions( 'north-america', qw/SanFrancisco Denver Toronto/ );
    $counter += &check_sorted_regions( 'south-america',
        qw/LaPlata BuenosAires RiodeJaneiro/ );
    $counter += &check_sorted_regions( 'africa', qw/Johannesburg CapeTown/ );
    $counter += &check_sorted_regions( 'asia', qw/Seoul Singapore Melbourne/ );

    return $counter;
}

my $counter = 1;
$counter += &check_regions(@regions);
$counter += &check_cities;
$counter += &check_bbbike_cities;
$counter += &check_match_cities;

plan tests => $counter;
__END__
