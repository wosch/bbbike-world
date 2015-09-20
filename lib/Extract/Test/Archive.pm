#!/usr/local/bin/perl
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# extract config and libraries

package Extract::Test::Archive;
use Test::More;
use Data::Dumper;

require Exporter;

#use base qw/Exporter/;
#our @EXPORT = qw(save_request complete_save_request check_queue Param large_int square_km);

use strict;
use warnings;

##########################
# helper functions
#

our $debug = 0;

# Extract::Utils::new->('q'=> $q, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {
        'supported_languages' => [ "de", "en" ],
        'lang'                => 'en',
        'format'              => '',
        'url'                 => '',
        'coords'              => '',
        'file'                => '',

        %args
    };

    bless $self, $class;
    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    if ( defined $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }

    $self->{'counter'} = 0;

    $self->init_env;
}

#############################################################################
# !!! Keep in sync !!!
# /cgi/extract.pl
#
#
## parameters for osm2XXX shell scripts
#$ENV{BBBIKE_EXTRACT_URL} = &script_url( $option, $obj );
#$ENV{BBBIKE_EXTRACT_COORDS} = qq[$obj->{"sw_lng"},$obj->{"sw_lat"} x $obj->{"ne_lng"},$obj->{"ne_lat"}];
#$ENV{'BBBIKE_EXTRACT_LANG'} = $lang;

sub init_env {
    my $self = shift;

    my $option = {
        'pbf2osm' => {
            'garmin_version'     => 'mkgmap-3334',
            'maperitive_version' => 'Maperitive-2.3.34',
            'osmand_version'     => 'OsmAndMapCreator-1.1.3',
            'mapsforge_version'  => 'mapsforge-0.4.3',
            'navit_version'      => 'maptool-0.5.0~svn5126',
            'shape_version'      => 'osmium2shape-1.0',
        }
    };

    $ENV{'BBBIKE_EXTRACT_GARMIN_VERSION'} =
      $option->{pbf2osm}->{garmin_version};
    $ENV{'BBBIKE_EXTRACT_MAPERITIVE_VERSION'} =
      $option->{pbf2osm}->{maperitive_version};
    $ENV{'BBBIKE_EXTRACT_OSMAND_VERSION'} =
      $option->{pbf2osm}->{osmand_version};
    $ENV{'BBBIKE_EXTRACT_MAPSFORGE_VERSION'} =
      $option->{pbf2osm}->{mapsforge_version};
    $ENV{'BBBIKE_EXTRACT_NAVIT_VERSION'} = $option->{pbf2osm}->{navit_version};
    $ENV{'BBBIKE_EXTRACT_SHAPE_VERSION'} = $option->{pbf2osm}->{shape_version};

#$ENV{BBBIKE_EXTRACT_URL}  = 'http://extract.bbbike.org/?sw_lng=-72.33&sw_lat=-13.712&ne_lng=-71.532&ne_lat=-13.217&format=png-google.zip&city=Cusco%2C%20Peru';
#$ENV{BBBIKE_EXTRACT_COORDS} = '-72.33,-13.712 x -71.532,-13.217';
}

sub validate {
    my $self = shift;

    my %args = @_;

    $self->check_checksum;

    return $self->{'counter'};
}

sub extract_file {
    my $self = shift;

    my $file     = shift;
    my $zip_file = $self->{'file'};

    my @data = ();
    if ( !-e $zip_file ) {
        die "zip file '$zip_file' does not exists\n";
    }

    if ( !open( IN, "unzip -p $zip_file '*/$file' |" ) ) {
        warn "unzip -p $zip_file: $!\n";
        return @data;
    }

    while (<IN>) {
        push @data, $_;
    }
    close IN;

    return @data;
}

sub check_checksum {
    my $self = shift;

    my @data = $self->extract_file('CHECKSUM.txt');

    is( scalar(@data), 2, "two checksums" );
    cmp_ok( length( $data[0] ), ">", 34, "md5 + text is larger than 32 bytes" );
    cmp_ok( length( $data[1] ),
        ">", 66, "sha256 + text is larger than 64 bytes" );

    $self->{'counter'} += 3;
}

1;

__DATA__;
