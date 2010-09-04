#!/usr/local/bin/perl
# Copyright (c) 2009-2010 Wolfram Schneider, http://bbbike.org
#
# BBBikeWorldDB.pm - module to parse bbbike @ world city database

package BBBikeWorldDB;

use IO::File;
use strict;
use warnings;

our $VERSION = 0.1;

our $debug = 1;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        'database'   => 'world/misc/cities.csv',
        'debug'      => $debug,
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

#
## City : Real Name : pref. language : local language : area : coord : population : step?
#Berlin:::::13.0109 52.3376 13.7613 52.6753:4500000:
#CambridgeMa:Cambridge (Massachusetts):en::other:-71.1986 42.3265 -71.0036 42.4285:1264990:
#

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

sub city  { return shift->{'_city'}; }
sub raw   { return shift->{'_raw'}; }
sub debug { return shift->{'debug'}; }

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
    my $self = shift;

    my $city      = shift;
    my $name      = shift or die "No city name given!\n";
    my $city_lang = shift || "de";

    warn "city: $city, name: $name, lang: $city_lang\n" if $self->debug >= 2;

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

