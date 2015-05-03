#!/usr/local/bin/perl
#
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# BBBikePoly.pm - polygon helper functions

package BBBikePoly;

use JSON;
use Data::Dumper;

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
    'centra-leurope' => { 'poly'  => [ 3.295,   42.571,  29.482,  60.992 ] },
    'asia'           => { 'poly'  => [ 43.505,  -53.122, 183.583, 63.052 ] },
    'planet'         => { 'poly2' => [ -180,    -90,     180,     90 ] },
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

1;

__DATA__;
