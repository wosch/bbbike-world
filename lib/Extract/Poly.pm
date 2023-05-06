#!/usr/local/bin/perl
# Copyright (c) 2012-2018 Wolfram Schneider, https://bbbike.org
#
# polygon helper functions

package Extract::Poly;

use CGI qw(escapeHTML);
use JSON;
use Math::Polygon::Transform qw(polygon_simplify);
use Math::Polygon::Calc qw();
use File::stat;
use Data::Dumper;
use FindBin;

use lib qw(world/lib);
use Extract::TileSize;
use Extract::Utils qw(square_km);

use strict;
use warnings;

###########################################################################
# config
#

our $debug = 1;

our $area = {
    'north-america'      => { 'poly' => [ -140.663, 6.783,  -45.554, 59.745 ] },
    'north-america-east' => { 'poly' => [ -94.5,    23.5,   -51.0,   56.0 ] },
    'north-america-west' => { 'poly' => [ -138.7,   23.5,   -92.2,   61 ] },
    'south-america'      => { 'poly' => [ -97.53,   -59.13, -28.544, 20.217 ] },
    'africa'             => { 'poly' => [ -23.196,  -39.96, 61.949,  38.718 ] },
    'africa-equatorial'  => { 'poly' => [ -18,      -11,    52,      17 ] },
    'asia'             => { 'poly' => [ 43.505,  -53.122, 179.99, 63.052 ] },
    'asia-south'       => { 'poly' => [ 60.0,    -12.0,   131,    56 ] },
    'asia-south-india' => { 'poly' => [ 66.1,    4.6,     90.6,   30.2 ] },
    'asia-south-china' => { 'poly' => [ 95.1,    19.1,    123.5,  45.1 ] },
    'europe'           => { 'poly' => [ -27.472, 26.682,  50.032, 72.282 ] },
    'europe-central'   => { 'poly' => [ 3.295,   45.3,    29.482, 63 ] },
    'europe-germany'   => { 'poly' => [ 4.892,   45.097,  17.614, 56.612 ] },
    'europe-germany-brandenburg' =>
      { 'poly' => [ 11.64, 51.58, 15.07, 53.31 ] },
    'europe-south'     => { 'poly' => [ -11.86, 28.29, 51.0,  46.7 ] },
    'europe-southwest' => { 'poly' => [ -11,    33,    19,    46 ] },
    'europe-southeast' => { 'poly' => [ 16,     25,    51.0,  48 ] },
    'europe-northwest' => { 'poly' => [ -26.60, 45.2,  8.3,   67.9 ] },
    'europe-east'      => { 'poly' => [ 13.15,  44.0,  42.58, 61.7 ] },

    # all
    'planet' => { 'poly2' => [ -180, -90, 180, 90 ] },

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
    if ( defined $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }

    $self->{'database'} = "world/etc/tile/pbf.csv";
}

#
# wrapper for x,y parameters
#
# ($lon1, $lat1 => $lon2, $lat2);
# (sw_lng, sw_lat, ne_lng, ne_lat)
sub rectangle_km {
    my $self = shift;
    my ( $x1, $y1, $x2, $y2, $factor ) = @_;

    return Extract::Utils::square_km( $y1, $x1, $y2, $x2, $factor );
}

sub list_subplanets {
    my $self = shift;
    my %args = @_;

    my $sort_by = $args{'sort_by'} // "";    # valid values are: skm, disk
    my $sub_planet_dir = $args{'sub_planet_dir'} // $self->{'sub_planet_dir'};

    # only regions with a 'poly' field
    my @list = grep { exists $area->{$_}->{'poly'} } keys %$area;

    # sort by square km size, smallest first
    if ( $sort_by eq 'skm' ) {
        my %hash =
          map { $_ => $self->rectangle_km( @{ $area->{$_}->{'poly'} } ) } @list;
        @list = sort { $hash{$a} <=> $hash{$b} } @list;
    }

    # sort by disk size, smallest first
    elsif ( $sort_by eq 'disk' ) {
        my %hash;
        foreach my $sub (@list) {

            # check for valid sub planet
            next if !defined $area->{$sub}->{'poly'};

            my $file = "$sub_planet_dir/$sub.osm.pbf";
            my $st   = stat($file);
            if ( !$st ) {
                warn
"Stat sub planet file pwd=$FindBin::Bin file=$file, assume size zero: $!\n";
                $hash{$sub} = 0;
            }
            else {
                $hash{$sub} = $st->size;
            }
        }

        @list = sort { $hash{$a} <=> $hash{$b} } keys %hash;
    }

    # sort alphabetically
    else {
        if ( $sort_by ne "" ) {
            warn
"Unknown sort_by='$sort_by' value, only skm and disk are allowed\n"
              if $debug >= 0;
        }

        @list = sort @list;
    }

    warn Dumper( \@list ) if $debug >= 2;

    return @list;
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

    my $tile = new Extract::TileSize(
        'database' => $self->{'database'},
        'debug'    => $debug
    );

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
    my $poly   = shift;

    my $coords = defined $poly ? $poly : $area->{$region}->{'poly'};

    my $obj = {
        "city"   => $region,
        "sw_lng" => $coords->[0],
        "sw_lat" => $coords->[1],
        "ne_lng" => $coords->[2],
        "ne_lat" => $coords->[3],
        "coords" => []
    };

    warn "get_job_obj: " . Dumper($obj) if $debug >= 2;
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

sub get_coords {
    my $self = shift;
    my $obj  = shift;

    my @c;

    # polygon
    if ( exists $obj->{"coords"} && scalar( @{ $obj->{"coords"} } ) ) {
        @c = @{ $obj->{coords} };
    }

    # rectangle
    else {
        push @c, [ $obj->{'sw_lng'}, $obj->{'sw_lat'} ];
        push @c, [ $obj->{'ne_lng'}, $obj->{'sw_lat'} ];
        push @c, [ $obj->{'ne_lng'}, $obj->{'ne_lat'} ];
        push @c, [ $obj->{'sw_lng'}, $obj->{'ne_lat'} ];
        push @c, [ $obj->{'sw_lng'}, $obj->{'sw_lat'} ];
    }

    warn "Polygon elements counter: @{[ scalar(@c) ]}\n" if $debug >= 2;
    if ( scalar(@c) <= 1 ) {
        warn Dumper( \@c, $obj ) if $debug >= 2;
        die "get_coords(): cannot get coordinates, give up!\n";
    }

    return @c;
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

    warn "create_poly_data: " . Dumper($obj) if $debug >= 2;

    my $data = "";
    my @poly = ();
    my $city = $obj->{"city"};

    if ( !defined $city ) {
        $city = "unknown-city";
        warn "reset undefined city to $city\n" if $debug >= 2;
    }
    $city = escapeHTML($city);

    my $counter = 0;
    my @c       = $self->get_coords($obj);

    # close polygone if not already closed
    if ( $c[0]->[0] ne $c[-1]->[0] || $c[0]->[1] ne $c[-1]->[1] ) {
        push @c, $c[0];
    }

    my $error = 0;

    # create poly data
    $data .= "$city\n";
    $data .= "0\n";

    for ( my $i = 0 ; $i <= $#c ; $i++ ) {
        my ( $lng, $lat ) = ( $c[$i]->[0], $c[$i]->[1] );
        if ( !$self->is_lng($lng) ) {
            warn "lng $lng is out of range -180 .. 180\n" if $debug >= 1;
            $error++;
        }
        if ( !$self->is_lat($lat) ) {
            warn "lat $lat is out of range -90 .. 90\n" if $debug >= 1;
            $error++;
        }

        $data .= sprintf( "   %E  %E\n", $lng, $lat );
        push @poly, [ $lng, $lat ];
    }

    $data .= "END\n";
    $data .= "END\n";

    $counter += $#c;

    if ($error) {
        warn
"Poly file is corrupt, no valid coordinates are given for city '$city'\n";
        return ( "", 0 );
    }
    else {
        return ( $data, $counter, \@poly );
    }
}

#
# upload poly file to extract an area:
#
# curl -sSf -F "submit=extract" -F "email=nobody@gmail.com" -F "city=Karlsruhe" -F "format=osm.pbf" \
#   -F "coords=@karlsruhe.poly" https://extract.bbbike.org | lynx -nolist -dump -stdin
#
sub parse_coords {
    my $self = shift;

    my $coords = shift;

    if ( $coords =~ /\|/ ) {
        return $self->parse_coords_string($coords);
    }
    elsif ( $coords =~ /\[/ ) {
        return $self->parse_coords_json($coords);
    }
    elsif ( $coords =~ /END/ ) {
        return $self->parse_coords_poly($coords);
    }
    else {
        warn "No known coords system found: '$coords'\n";
        return ();
    }
}

sub parse_coords_json {
    my $self = shift;

    my $coords = shift;

    my $perl;
    eval { $perl = decode_json($coords) };
    if ($@) {
        warn "decode_json: $@ for $coords\n";
        return ();
    }

    return @$perl;
}

sub parse_coords_poly {
    my $self = shift;

    my $coords = shift;

    my @list = split "\n", $coords;
    my @data;
    foreach (@list) {
        next if !/^\s+/;
        chomp;

        my ( $lng, $lat ) = split;
        push @data, [ $lng, $lat ];
    }

    return @data;
}

sub parse_coords_string {
    my $self = shift;

    my $coords = shift;
    my @data;

    my @coords = split /\|/, $coords;

    foreach my $point (@coords) {
        my ( $lng, $lat ) = split ",", $point;
        push @data, [ $lng, $lat ];
    }

    return @data;
}

# fewer points, max. 1024 points in a polygon
sub normalize_polygon {
    my $self = shift;

    my $poly = shift;
    my $max = shift || 1024;

    my $same = '0.001';
    warn "Polygon input: " . Dumper($poly) if $debug >= 3;

    # max. 10 meters accuracy
    my @poly = polygon_simplify( 'same' => $same, @$poly );

    # but not more than N points
    if ( scalar(@poly) > $max ) {
        warn "Resize 0.01 $#poly\n" if $debug >= 1;
        @poly = polygon_simplify( 'same' => 0.01, @$poly );
        if ( scalar(@poly) > $max ) {
            warn "Resize $max points $#poly\n" if $debug >= 1;
            @poly = polygon_simplify( max_points => $max, @poly );
        }
    }

    return @poly;
}

# just a wrapper
sub polygon_bbox {
    my $self = shift;

    return Math::Polygon::Calc::polygon_bbox(@_);
}

1;

__DATA__;
