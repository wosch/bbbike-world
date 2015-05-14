#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# polygon helper functions

package Extract::Poly;

use JSON;
use CGI qw(escapeHTML);
use Data::Dumper;

use lib qw(world/lib);
use Extract::TileSize;

use strict;
use warnings;

###########################################################################
# config
#

our $debug = 1;

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

    # test data
    'Berlin' => { 'poly2' => [ 12.76, 52.23, 13.98, 52.82 ] },
    'Alien'  => { 'poly2' => [ 181,   91,    -300,  0 ] },
};

##########################
# helper functions
#

# Extract::Poly::new->('debug'=> 2, 'option' => $option)
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

    my $tile = new Extract::TileSize( 'database' => $self->{'database'} );

    if ( !$area->{$region} ) {
        warn "Area '$region' does not exists, skip\n" if $debug;
        return 0;
    }

    my $size = $tile->area_size( @{ $area->{$region}->{'poly'} },
        Extract::TileSize::FRACTAL_REAL );
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

sub is_lng {
    my $self = shift;
    my $val  = shift;

    return $self->is_coord( $val, 180 );
}

sub is_lat {
    my $self = shift;
    my $val  = shift;

    return $self->is_coord( $val, 90 );
}

sub is_coord {
    my $self = shift;

    my $number = shift;
    my $max    = shift;

    return 0 if $number eq "";
    return 0 if $number !~ /^[\-\+]?[0-9]+(\.[0-9]+)?$/;

    return $number <= $max && $number >= -$max ? 1 : 0;
}

sub create_overpass_api_url {
    my $self = shift;
    my %args = @_;

    my $obj = $args{'job'};
    warn Dumper($obj) if $debug >= 2;

    my $url = "http://overpass-api.de/api/interpreter?data=[out:xml];node%28";
    $url .= qq|$obj->{"sw_lat"},$obj->{"sw_lng"},|;
    $url .= qq|$obj->{"ne_lat"},$obj->{"ne_lng"}|;
    $url .= "%29;out;";

    return $url;
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

    my $error = 0;

    # create poly data
    my $city = escapeHTML( $obj->{"city"} );
    $data .= "$city\n";
    $data .= "0\n";

    for ( my $i = 0 ; $i <= $#c ; $i++ ) {
        my ( $lng, $lat ) = ( $c[$i]->[0], $c[$i]->[1] );
        if ( !$self->is_lng($lng) ) {
            warn "lng $lng is out of range -180 .. 180\n";
            $error++;
        }
        if ( !$self->is_lat($lat) ) {
            warn "lat $lat is out of range -90 .. 90\n";
            $error++;
        }

        $data .= sprintf( "   %E  %E\n", $lng, $lat );
    }

    $data .= "END\n";
    $data .= "END\n";

    $counter += $#c;

    if ($error) {
        warn "Poly file is currupt, no valid coordinates are given\n";
        return ( "", 0 );
    }
    else {
        return ( $data, $counter );
    }
}

1;

__DATA__;
