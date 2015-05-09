#!/usr/local/bin/perl
#
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# BBBikePoly.pm - polygon helper functions

package BBBikePoly;

use JSON;
use Data::Dumper;
use CGI qw(escapeHTML);

use lib qw(world/bin);
use TileSize;

use strict;
use warnings;

###########################################################################
# config
#

our $area = {
    'noth-america' => {
        'poly' => [ -140.663, 6.783, -45.554, 59.745 ]
        ,    # 'file' => foo.osm.pbf, size => 3045
    },
    'south-america'  => { 'poly'  => [ -97.53,  -59.13,  -28.544, 20.217 ] },
    'africa'         => { 'poly'  => [ -23.196, -39.96,  61.949,  38.718 ] },
    'europe'         => { 'poly'  => [ -27.472, 26.682,  50.032,  72.282 ] },
    'central-europe' => { 'poly'  => [ 3.295,   42.571,  29.482,  60.992 ] },
    'asia'           => { 'poly'  => [ 43.505,  -53.122, 179.99,  63.052 ] },
    'planet'         => { 'poly2' => [ -180,    -90,     180,     90 ] },

    'Berlin' => { 'poly2' => [ 12.76, 52.23, 13.98, 52.82 ] },
};

our $debug = 1;

##########################
# helper functions
#

# BBBikePoly::new->('debug'=> 2, 'option' => $option)
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

    $self->{'database'} = "world/etc/tile/tile-pbf.csv";
}

sub list_subplanets {
    my $self = shift;

    # only regions with a 'poly' field
    my @list = grep { exists $area->{$_}->{'poly'} } keys %$area;

    return sort @list;
}

# scale file size in x.y MB
sub file_size_mb {
    my $self = shift;
    my $size = shift;

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $size / 1024 / 1024 ) / $scale;
        return $result if $result > 0;
    }

    return "0.0";
}

sub subplanet_size {
    my $self   = shift;
    my $region = shift;

    my $tile = new TileSize( 'database' => $self->{'database'} );

    if ( !$area->{$region} ) {
        warn "Area '$region' does not exists, skip\n" if $debug;
        return 0;
    }

    my $size = $tile->area_size( @{ $area->{$region}->{'poly'} },
        TileSize::FRACTAL_REAL );
    $size = int( $size * 1000 + 0.5 ) / 1000;

    return $size;
}

sub get_job_obj {
    my $self   = shift;
    my $region = shift;

    my $coords = $area->{$region}->{'poly'};

    my $obj = {
        "city"   => $region,
        "sw_lng" => $coords->[0],
        "sw_lat" => $coords->[1],
        "ne_lng" => $coords->[2],
        "ne_lat" => $coords->[3],
        "coords" => []
    };

    warn Dumper($obj) if $debug >= 2;
    return $obj;
}

#
# create a poly file based on a rectangle or polygon coordinates
#
# $obj->{ 'coords' => [ ... ] };
#
# $obj-> {
#   "ne_lng" => -2.2226,
#   "ne_lat" => 47.2941,
#   "sw_lat" => 47.2653,
#   "sw_lng" -> -2.2697,
# }
#
sub create_poly_data {
    my $self = shift;

    my %args = @_;
    my $obj  = $args{'job'};

    warn Dumper($obj) if $debug >= 2;

    my $data = "";

    my $counter = 0;
    my @c;

    # rectangle
    if ( !scalar( @{ $obj->{"coords"} } ) ) {
        push @c, [ $obj->{'sw_lng'}, $obj->{'sw_lat'} ];
        push @c, [ $obj->{'ne_lng'}, $obj->{'sw_lat'} ];
        push @c, [ $obj->{'ne_lng'}, $obj->{'ne_lat'} ];
        push @c, [ $obj->{'sw_lng'}, $obj->{'ne_lat'} ];
    }

    # polygon
    else {
        @c = @{ $obj->{coords} };
    }

    # close polygone if not already closed
    if ( $c[0]->[0] ne $c[-1]->[0] || $c[0]->[1] ne $c[-1]->[1] ) {
        push @c, $c[0];
    }

    # create poly data
    my $city = escapeHTML( $obj->{"city"} );
    $data .= "$city\n";
    $data .= "0\n";

    for ( my $i = 0 ; $i <= $#c ; $i++ ) {
        my ( $lng, $lat ) = ( $c[$i]->[0], $c[$i]->[1] );
        $data .= sprintf( "   %E  %E\n", $lng, $lat );
    }

    $data .= "END\n";
    $data .= "END\n";

    $counter += $#c;
    return ( $data, $counter );
}

1;

__DATA__;
