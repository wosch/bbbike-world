#!/usr/local/bin/perl
# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org
#
# TileSize.pm - module to guess size of a lat,lng tile

package TileSize;

use IO::File;
use Data::Dumper;
use POSIX;
use GIS::Distance::Lite;
use Storable;
use Digest::MD5 qw(md5_hex);
use File::stat;

use strict;
use warnings;

our $VERSION = 1.2;

use constant {
    FRACTAL_100  => 0,
    FRACTAL_50   => 1,
    FRACTAL_REAL => 2
};

our $debug     = 0;
our $use_cache = 1;

# default size if the coordinates are not in the database
our $default_size = 4;

# guess size based on factor of known size of osm.pbf
our $factor = {
    'garmin-bbbike.zip'  => 0.582,
    'garmin-cycle.zip'   => 0.581,
    'garmin-leisure.zip' => 0.755,
    'garmin-osm.zip'     => 0.583,
    'mapsforge-osm.zip'  => 0.80,
    'navit.zip'          => 0.75,
    'o5m.bz2'            => 0.88,
    'o5m.gz'             => 1.04,
    'o5m.xz'             => 1.04,
    'obf.zip'            => 1.4,
    'osm.bz2'            => 1.5,
    'osm.gz'             => 1.93,
    'osm.xz'             => 1.8,
    'shp.zip'            => 1.5,
    'pbf'                => 1,
};

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        'debug'    => $debug,
        'format'   => 'pbf',
        'database' => 'world/etc/tile/tile-test.csv',
        'factor'   => $factor,
        'tmpdir'   => '/var/tmp',
        '_size'    => {},
        %args,
    };

    bless $self, $class;
    $self->parse_database;
    $debug = $self->{'debug'};

    warn Dumper($self) if $self->{'debug'} >= 3;
    return $self;
}

sub get_cache_file {
    my $self = shift;

    my $hostname = $ENV{HTTP_HOST} || "localhost";
    my $file =
        $self->{'tmpdir'}
      . "/_tilesize-$<-$hostname-"
      . md5_hex( $self->{'database'} . ".db" );
    return $file;
}

sub parse_database {
    my $self = shift;
    my %size;

    %size = $self->get_cache() if $use_cache;
    if (%size) {
        warn "Get size from cache\n" if $debug >= 1;
        return $self->{_size} = \%size;
    }

    my $db = $self->{'database'};
    my $fh = new IO::File $db, "r" or die "open: '$db' $!\n";
    binmode $fh, ":utf8";

    my %raw;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        next if /^#/ || $_ eq "";

        my ( $size, $lng_sw, $lat_sw, $lng_ne, $lat_ne ) = split(/\s+/);

        $size{"$lng_sw,$lat_sw"} = $size;
    }
    close $fh;

    $self->set_cache( \%size ) if $use_cache;
    return $self->{_size} = \%size;
}

sub get_cache {
    my $self = shift;

    my $file = $self->get_cache_file;
    my $st   = stat($file);
    if ( !defined $st ) {
        warn "No cache file $file found\n" if $debug >= 2;
        return;
    }
    if ( $st->mtime + 24 * 3600 < time() ) {
        warn "Cache file $file expired\n";
        return;
    }

    warn "Get cache $file\n" if $debug >= 1;
    my $size = Storable::retrieve $file;
    if ( !defined $size ) {
        warn "Could not fetch storable $file\n";
        return;
    }

    return %$size;
}

sub set_cache {
    my $self  = shift;
    my $cache = shift;

    my $file = $self->get_cache_file;
    warn "Set cache $file\n" if $debug >= 1;
    if ( !Storable::nstore( $cache, $file ) ) {
        warn "Could not store cache $file: $!\n";
    }

    return;
}

# ($lat1, $lon1 => $lat2, $lon2);
sub square_km {
    my $self = shift;
    my ( $x1, $y1, $x2, $y2 ) = @_;

    my $height = GIS::Distance::Lite::distance( $x1, $y1 => $x1, $y2 ) / 1000;
    my $width  = GIS::Distance::Lite::distance( $x1, $y1 => $x2, $y1 ) / 1000;

    warn "height: $height, width: $width, $x1,$y1 => $x2,$y2\n" if $debug >= 3;
    return ( $height * $width );
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

    # cannot handle > 360 degrees lng, or >90, <-90 lat
    if ( $lng_sw > 360 || $lng_sw < -360 ) {
        warn "lng sw: -360 < $lng_sw <= 360, give up!\n" if $debug >= 1;
        return -1;
    }
    if ( $lng_ne > 360 || $lng_ne < -360 ) {
        warn "lng ne: -360 < $lng_ne <= 360, give up!\n" if $debug >= 1;
        return -1;
    }

    if ( $lat_sw < -90 || $lat_sw > 90 ) {
        warn "lat sw: -90 < $lat_sw <= 90, give up!\n" if $debug >= 1;
        return -1;
    }
    if ( $lat_ne < -90 || $lat_ne > 90 ) {
        warn "lat ne: -90 < $lat_ne <= 90, give up!\n" if $debug >= 1;
        return -1;
    }

    # handle ranges between 180 .. 360 degrees
    if ( $lng_sw > 180 ) {
        my $reset = $lng_sw - 360;
        warn "lng sw: $lng_sw > 180, reset to $reset\n" if $debug >= 1;
        $lng_sw = $reset;
    }
    if ( $lng_sw < -180 ) {
        my $reset = $lng_sw + 360;
        warn "lng sw: $lng_sw < -180, reset to $reset\n" if $debug >= 1;
        $lng_sw = $reset;
    }
    if ( $lng_ne > 180 ) {
        my $reset = $lng_ne - 360;
        warn "lng ne: $lng_ne > 180, reset to $reset\n" if $debug >= 1;
        $lng_ne = $reset;
    }
    if ( $lng_ne < -180 ) {
        my $reset = $lng_ne + 360;
        warn "lng ne: $lng_ne < -180, reset to $reset\n" if $debug >= 1;
        $lng_ne = $reset;
    }

    # broken lat values? SW is below NE
    if ( $lat_sw > $lat_ne ) {
        warn "lat sw: $lat_sw is larger than lat ne: $lat_ne, give up!\n"
          if $debug >= 1;
        return -1;
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
    elsif ( $lng_sw > $lng_ne ) {
        warn "lng sw: $lng_sw is larger than lng ne: $lng_ne, give up!\n"
          if $debug >= 1;
        return -1;
    }

    elsif ( abs( $lng_sw - $lng_ne ) > 180 ) {
        warn "lng distance: $lng_sw - $lng_ne > 180, give up!\n" if $debug >= 1;
        return -1;
    }

    # call real function
    else {
        return $self->_area_size( $lng_sw, $lat_sw, $lng_ne, $lat_ne, $parts );
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

    warn "area size: $lng_sw,$lat_sw,$lng_ne,$lat_ne", " :: ",
      "$lng_sw2,$lat_sw2,$lng_ne2,$lat_ne2\n"
      if $debug >= 1;

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
