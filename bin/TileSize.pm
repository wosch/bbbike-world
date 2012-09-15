#!/usr/local/bin/perl
# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org
#
# TileSize.pm - module to guess size of a lat,lng tile

package TileSize;

use IO::File;
use Data::Dumper;
use POSIX;
use GIS::Distance::Lite;

use strict;
use warnings;

our $VERSION = 1.1;

use constant {
    FRACTAL_100  => 0,
    FRACTAL_50   => 1,
    FRACTAL_REAL => 2
};

our $debug = 0;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        'debug'    => $debug,
        'format'   => 'pbf',
        'database' => 'world/etc/tile/tile-test.csv',
        '_size'    => {},
        %args,
    };

    bless $self, $class;
    $self->parse_database;
    $debug = $self->{'debug'};

    warn Dumper($self) if $self->{'debug'} >= 3;
    return $self;
}

sub parse_database {
    my $self = shift;

    my $db = $self->{'database'};
    my $fh = new IO::File $db, "r" or die "open: '$db' $!\n";
    binmode $fh, ":utf8";

    my %size;
    my %raw;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        next if /^#/ || $_ eq "";

        my ( $size, $lng_sw, $lat_sw, $lng_ne, $lat_ne ) = split(/\s+/);

        $size{"$lng_sw,$lat_sw"} = $size;
    }
    close $fh;

    return $self->{_size} = \%size;
}

# ($lat1, $lon1 => $lat2, $lon2);
sub square_km {
    my $self = shift;
    my ( $x1, $y1, $x2, $y2 ) = @_;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 ) / 1000;
    my $width  = GIS::Distance::Lite::distance( $x1, $y1 => $x2, $y1 ) / 1000;

    warn "height: $height, width: $width, $x1,$y1 => $x2,$y2\n" if $debug >= 3;
    return int( $height * $width );
}

sub total {
    my $self  = shift;
    my $total = 0;
    my $db    = $self->{_size};

    for ( my $lng = -180 ; $lng < 180 ; $lng++ ) {
        for ( my $lat = -90 ; $lat < 90 ; $lat++ ) {
            my $key = "$lng,$lat";
            if ( exists $db->{$key} ) {
                warn "$key $db->{$key}\n" if $debug >= 3;
                $total += $db->{$key};
            }
        }
    }

    return $total;
}

# wrapper to catch date border special case
sub area_size {
    my $self = shift;
    my ( $lng_sw, $lat_sw, $lng_ne, $lat_ne, $parts ) = @_;

    warn "@_ lat sw: $lat_sw, ne: $lat_ne, ", $lat_sw - $lat_ne, "\n"
      if $debug >= 2;

    # broken lat values? SW is below NE
    if ( $lat_sw > $lat_ne ) {
        warn "lat sw: $lat_sw is larger than lat ne: $lat_ne, give up!\n"
          if $debug >= 0;
        return 0;
    }

    # date border? Split the rectangle in to parts at the date border
    elsif ( $lng_sw > 0 && $lng_ne < 0 ) {
        my $left_area =
          $self->area_size( $lng_sw, $lat_sw, 180, $lat_ne, $parts );
        my $right_area =
          $self->area_size( -180, $lat_sw, $lng_ne, $lat_ne, $parts );

        return $left_area + $right_area;
    }

    # broken lng value? SW is below NE
    elsif ( $lng_sw > $lng_ne || abs( $lng_sw - $lng_ne ) > 180 ) {
        warn "lon sw: $lng_sw is smaller than lon ne: $lng_ne, give up!\n"
          if $debug >= 0;
        return 0;
    }

    # call real function
    else {
        return $self->_area_size(@_);
    }
}

#
# compute the size of an area: lng_sw,lat_sw x lng_ne,lat_ne FLAG
#
sub _area_size {
    my $self = shift;
    my ( $lng_sw, $lat_sw, $lng_ne, $lat_ne, $parts ) = @_;

    my ( $lng_sw2, $lat_sw2, $lng_ne2, $lat_ne2 );

    my $db   = $self->{_size};
    my $size = 0;

    $parts = FRACTAL_100 if !defined $parts;

    # padding south-west, lower left corner
    $lng_sw2 = POSIX::floor($lng_sw);
    $lat_sw2 = POSIX::floor($lat_sw);

    # padding north-east, upper-right corner
    $lng_ne2 = POSIX::ceil($lng_ne);
    $lat_ne2 = POSIX::ceil($lat_ne);

    warn "$lng_sw,$lat_sw,$lng_ne,$lat_ne", " :: ",
      "$lng_sw2,$lat_sw2,$lng_ne2,$lat_ne2\n"
      if $debug > 0;

    sub W { $debug >= 2 ? warn $_[0] . "\n" : 1 }
    my $tile_parts = 0;

    for ( my $i = $lng_sw2 ; $i < $lng_ne2 ; $i++ ) {    # x-axis
        for ( my $j = $lat_sw2 ; $j < $lat_ne2 ; $j++ ) {    # y-axis
            my $key = "$i,$j";
            if ( exists $db->{$key} ) {
                my $factor = 1;
                warn "Add key: $key: $db->{$key}\n" if $debug >= 2;

                if (
                       ( $i == $lng_sw2 && $lng_sw2 < $lng_sw && W("x left") )
                    || ( $j == $lat_sw2 && $lat_sw2 < $lat_sw && W("y down") )
                    || (   $i + 1 == $lng_ne2
                        && $lng_ne2 > $lng_ne
                        && W("x right") )
                    || (   $j + 1 == $lat_ne2
                        && $lat_ne2 > $lat_ne
                        && W("y top") )
                  )
                {
                    warn
                      "Parts detected: $i,$j $lng_sw,$lat_sw,$lng_ne,$lat_ne",
                      " :: $lng_sw2,$lat_sw2,$lng_ne2,$lat_ne2\n"
                      if $debug >= 2;

                    $tile_parts += 1;

                    # simple version: just use half size
                    if ( $parts == FRACTAL_50 ) {
                        $factor = 0.5;
                    }

                    # compute the real size of a tile part, in percent
                    elsif ( $parts == FRACTAL_REAL ) {
                        my $square_km =
                          $self->square_km( $j, $i, $j + 1, $i + 1 );
                        my ( $x1, $y1, $x2, $y2 ) = ( $i, $j, $i + 1, $j + 1 );
                        $x1 = $lng_sw if $i == $lng_sw2 && $lng_sw2 < $lng_sw;
                        $y1 = $lat_sw if $j == $lat_sw2 && $lat_sw2 < $lat_sw;
                        $x2 = $lng_ne
                          if $i + 1 == $lng_ne2 && $lng_ne2 > $lng_ne;
                        $y2 = $lat_ne
                          if $j + 1 == $lat_ne2 && $lat_ne2 > $lat_ne;

                        my $square_km_part =
                          $self->square_km( $y1, $x1, $y2, $x2 );

                        $factor = $square_km_part / $square_km;
                        warn
"square km: $i,$j $square_km, $square_km_part, factor: $factor\n"
                          if $debug >= 2;
                    }
                }
                $size += $db->{$key} * $factor;
            }
        }
    }

    warn "Got $tile_parts parts\n" if $debug > 0;
    return $size;
}

1;
