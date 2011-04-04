#!/usr/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# location.cgi - find a bbbike city close to the user

use CGI qw/-utf-8/;
use IO::File;
use CGI::Carp;
use JSON;

use lib '../world/bin';
use lib '../../world/bin';
use BBBikeWorldDB;

use strict;
use warnings;

my $q        = new CGI;
my $debug    = 1;
my $database = '../world/etc/cities.csv';

sub point_in_grid {
    my ( $x1, $y1, $gridx1, $gridy1, $gridx2, $gridy2 ) = @_;
    return ( $x1 >= $gridx1
          && $x1 <= $gridx2
          && $y1 >= $gridy1
          && $y1 <= $gridy2 );
}

sub get_city {
    my ( $hash, $lat, $lng ) = @_;
    return if !$lat || !$lng;

    my @cities;
    foreach my $city ( keys %{$hash} ) {
        my @coord = split( /\s+/, $hash->{$city}{"coord"} );
        if ( point_in_grid( $lng, $lat, @coord ) ) {
            push @cities, $city;
        }
    }
    return @cities;
}

##############################################################################################
#
# main
#

my $db = BBBikeWorldDB->new( 'database' => $database );

print $q->header(
    -type    => 'application/json;charset=UTF-8',
    -expires => '+5m'
);

my $lat = $q->param('lat') || "";
my $lng = $q->param('lng') || "";

# $lat = 52.5924955; $lng= 13.4619832; # Berlin-Blankenburg, inside area "Berlin" and "Oranienburg"

# "13.3888548", "52.5170397" );
my @city = get_city( $db->city, $lat, $lng );
push @city, "NO_CITY" if scalar(@city) <= 0;

my $json = new JSON;
print $json->encode( \@city );

my $remote_host = $q->remote_host;
warn "lat: $lat, lng: $lng, city: ", join( ",", @city ), " ip: $remote_host\n"
  if $debug;

