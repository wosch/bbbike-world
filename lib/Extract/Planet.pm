#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# planet helper functions

package Extract::Planet;

use JSON;
use Math::Polygon;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Poly;

use strict;
use warnings;

###########################################################################
# config
#

our $debug          = 1;
our $sub_planet_dir = '../osm/download/sub-planet';

##########################
# helper functions
#

# Extract::Planet::new->('debug'=> 2, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {%args};

    bless $self, $class;

    $self->init;
    return $self;
}

sub init {
    my $self = shift;

    # set global debug variable
    if ( $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }
}

# check if the inner polygon is inside the outer polygon
sub sub_polygon {
    my $self = shift;

    my %args  = @_;
    my $outer = $args{'outer'};
    my $inner = $args{'inner'};

    my $poly = Math::Polygon->new(@$outer);
    my $flag = 0;

    foreach my $point (@$inner) {
        if ( !$poly->contains($point) ) {
            return 0;
        }
    }

    return 1;
}

sub get_polygon {
    my $self = shift;
    my $poly = shift;
    my $name = shift;
    my $list = shift;

    my $obj = $poly->get_job_obj( $name, $list );
    my ( $data, $counter, $polygon ) = $poly->create_poly_data( 'job' => $obj );

    return $polygon;
}

# find the smallest matching sub-planet
sub get_smallest_planet {
    my $self    = shift;
    my $obj     = shift;
    my $regions = shift;

    my $poly = new Extract::Poly( 'debug' => $debug );
    my @regions = $regions ? @$regions : $poly->list_subplanets(1);

    my ( $data, $counter, $city_polygon ) =
      $poly->create_poly_data( 'job' => $obj );
    warn Dumper($city_polygon) if $debug >= 2;

    foreach my $outer (@regions) {
        my $inner = $self->sub_polygon(
            'inner' => $city_polygon,
            'outer' => $self->get_polygon( $poly, $outer )
        );

        if ($inner) {
            return $outer;
        }
    }

    # nothing found, fall back to full planet
    return "planet";
}

1;

__DATA__;
