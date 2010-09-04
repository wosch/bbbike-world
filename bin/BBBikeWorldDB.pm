#!/usr/local/bin/perl
# Copyright (c) 2009-2010 Wolfram Schneider, http://bbbike.org
#
# BBBikeWorldDB.pm - module to parse bbbike @ world city database

package BBBikeWorldDB;

use IO::File;
use strict;
use warnings;

our $VERSION = 0.1;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        'database'   => 'world/misc/cities.csv',
        'lang'       => 'de',
        'local_lang' => '',
        'area'       => 'de',
        'step'       => '0.02',
        '_city'      => {},
    };

    bless $self, $class;

    $self->parse_database;
    return $self;
}

sub parse_database {
    my $self = shift;

    my $db = $self->{'database'};
    my $fh = new IO::File $db, "r" or die "open: $db $!\n";

    my %hash;
    my %raw;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        next if /^#/ || $_ eq "";

        my ( $city, $name, $lang, $local_lang, $area, $coord, $population,
            $step )
          = split(/:/);

        next if $city eq 'dummy';

        $hash{$city} = {
            city       => $city,
            name       => $name,
            lang       => $lang || "de",
            local_lang => $local_lang || "",
            step       => $step || "0.02",
            area       => $area || "de",
            coord      => $coord,
            population => $population || 1,
        };

        $raw{$city} = [
            $city, $name,  $lang,       $local_lang,
            $area, $coord, $population, $step
        ];
    }
    close $fh;

    $self->{'_city'} = \%hash;
    $self->{'_raw'}  = \%raw;

    return $self->city;
}

sub city { return shift->{'_city'}; }
sub raw  { return shift->{'_raw'}; }

sub list_cities {
    my $self = shift;

    if ( $self->city ) {
        return sort keys %{ $self->city };
    }
    else {
        return;
    }
}

# select city name by language
sub select_city_name {
    my $city      = shift;
    my $name      = shift or die "No city name given!\n";
    my $city_lang = shift || "de";

    my %hash;
    $hash{ALL} = $city;
    foreach my $n ( split /\s*,\s*/, $name ) {
        my ( $lang, $city_name ) = split( /!/, $n );
        if ($city_name) {
            $hash{$lang} = $city_name;
        }

        # no city language defined, use default
        else {
            $hash{ALL} = $lang;
        }
    }

    #use Data::Dumper; warn Dumper( \%hash );
    return exists( $hash{$city_lang} ) ? $hash{$city_lang} : $hash{ALL};
}

