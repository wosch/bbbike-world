#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# test script to check which sub-planets can be used
#
# /this/script ./extract/trash/*.json
#
use JSON;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Utils;
use Extract::Planet;
use Extract::Poly;

use strict;
use warnings;

my $debug   = 0;
my $poly    = new Extract::Poly( 'debug' => $debug );
my $planet         = new Extract::Planet( 'debug' => $debug );
my @regions = $poly->list_subplanets(1);
my @regions_sorted = $poly->list_subplanets(1);

sub get_polygon {
    my $name = shift;
    my $list = shift;

    my $obj = $poly->get_job_obj( $name, $list );
    my ( $data, $counter, $polygon ) = $poly->create_poly_data( 'job' => $obj );
    return $polygon;
}

sub get_smallest_planet {
    my $obj = shift;
    my $regions = shift;
    
    my @regions = @$regions;
    
    my ($data, $counter, $city_polygon) =  $poly->create_poly_data( 'job' => $obj );
    warn Dumper($city_polygon) if $debug >= 1;
    
    foreach my $outer (@regions_sorted) {
        my $inner = $planet->sub_polygon(
            'inner' => $city_polygon,
            'outer' => get_polygon($outer)
        );
        
        if ($inner) {
            return $outer;
        }
    }
    
    return "planet";
}

#############################################
# main
#

binmode(\*STDOUT, ":utf8");
my $extract_utils = new Extract::Utils;
die "No file given\n" if !@ARGV;

foreach my $file (@ARGV) {
my $obj = $extract_utils->parse_json_file($file);
next if !exists $obj->{"coords"} or ref $obj->{"coords"} ne 'ARRAY';

warn Dumper($obj) if $debug >= 2;

printf("%s\t%s\n", $obj->{"city"}, &get_smallest_planet($obj, \@regions_sorted));
}


__END__
