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
    };

    bless $self, $class;
}

sub parse_database {
    my $self = shift;

    my $db = $self->{'database'};
    my $fh = new IO::File $db, "r" or die "open: $!\n";

    my %hash;
    my %raw;
    while (<$fh>) {
        chomp;
        s/^\s+//;
        next if /^#/ || $_ eq "";

        my ( $city, $name, $lang, $local_lang, $area, $coord, $population,
            $step )
          = split(/:/);
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

    $self->{'city'} = \%hash;
    $self->{'raw'}  = \%raw;

    return $self->city;
}

sub city { return shift->{'city'}; }
sub raw  { return shift->{'raw'}; }

