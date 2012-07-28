#!/usr/local/bin/perl
# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org
#
# TileSize.pm - module to guess size of a lat,lng tile

package TileSize;

use IO::File;
use Data::Dumper;
use strict;
use warnings;

our $VERSION = 0.1;

our $debug = 1;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        'debug'    => $debug,
        'format'   => 'pbf',
        'database' => 'world/etc/tiles-pbf.csv',
        '_size'    => {},
        %args,
    };

    bless $self, $class;
    $self->parse_database;

    print Dumper($self) if $self->{'debug'} >= 2;
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
                warn "$key $db->{$key}\n" if $debug >= 2;
                $total += $db->{$key};
            }
        }
    }

    return $total;
}

1;
