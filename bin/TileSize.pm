#!/usr/local/bin/perl
# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org
#
# TileSize.pm - module to guess size of a lat,lng tile

package TileSize;

use IO::File;
use Data::Dumper;
use POSIX;
use strict;
use warnings;

our $VERSION = 0.1;

our $debug = 1;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        'debug'    => $debug,
        'format'   => 'pbf',
        'database' => 'world/etc/tile/tile.csv',
        '_size'    => {},
        %args,
    };

    bless $self, $class;
    $self->parse_database;
    $debug = $self->{'debug'};

    print Dumper($self) if $self->{'debug'} >= 3;
    return $self;
}

sub parse_database {
    my $self = shift;

    my $db = $self->{'database'};
    my $fh = new IO::File $db, "r" or die "open: $db $!\n";
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

# compute the size of an area lng_sw,lat_sw x lng_ne,lat_ne
sub area_size {
    my $self = shift;
    my ( $lng_sw, $lat_sw, $lng_ne, $lat_ne, $parts ) = @_;
    my ( $lng_sw2, $lat_sw2, $lng_ne2, $lat_ne2 );

    my $db   = $self->{_size};
    my $size = 0;

    $lng_sw2 = POSIX::floor($lng_sw);
    $lat_sw2 = POSIX::floor($lat_sw);

    $lng_ne2 = POSIX::ceil($lng_ne);
    $lat_ne2 = POSIX::ceil($lat_ne);

    warn "$lng_sw,$lat_sw,$lng_ne,$lat_ne", " :: ",
      "$lng_sw2,$lat_sw2,$lng_ne2,$lat_ne2\n"
      if $debug;

    sub W { warn $_[0] . "\n" if $debug >= 2 }

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
"Parts detected: $i,$j $lng_sw,$lat_sw,$lng_ne,$lat_ne :: $lng_sw2,$lat_sw2,$lng_ne2,$lat_ne2\n"
                      if $debug >= 2;
                    $tile_parts += 1;
                    $factor = 0.5 if $parts;
                }
                $size += $db->{$key} * $factor;
            }
        }
    }

    warn "Got $tile_parts parts\n" if $debug;
    return $size;
}

1;
