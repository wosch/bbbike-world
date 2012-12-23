#!/usr/local/bin/perl
# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org
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

# Argument: [x1,y1], [x2, y2]
sub _strecke {
    CORE::sqrt(
        sqr( $_[0]->[0] - $_[1]->[0] ) + sqr( $_[0]->[1] - $_[1]->[1] ) );
}

sub sqr {
    $_[0] * $_[0];
}

sub point_in_grid {
    my ( $x1, $y1, $gridx1, $gridy1, $gridx2, $gridy2 ) = @_;

    if (   $x1 >= $gridx1
        && $x1 <= $gridx2
        && $y1 >= $gridy1
        && $y1 <= $gridy2 )
    {

        # return distance to middle point of the area
        return _strecke(
            [
                $gridx1 + ( $gridx2 - $gridx1 ) / 2,
                $gridy1 + ( $gridy2 - $gridy1 ) / 2
            ],
            [ $x1, $y1 ]
        );
    }

    else {
        return 0;
    }
}

sub get_city {
    my ( $hash, $lat, $lng ) = @_;
    return if !$lat || !$lng;

    my @cities;
    foreach my $city ( keys %{$hash} ) {
        my @coord = split( /\s+/, $hash->{$city}{"coord"} );
        if ( my $distance = point_in_grid( $lng, $lat, @coord ) ) {
            push @cities, [ $city, $distance ];
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
    -type                        => 'application/json;charset=UTF-8',
    -expires                     => '+5m',
    -access_control_allow_origin => '*',
);

my $lat = $q->param('lat') || "";
my $lng = $q->param('lng') || "";

# $lat = 52.5924955; $lng= 13.4619832; # Berlin-Blankenburg, inside area "Berlin" and "Oranienburg"
# $lat = 52.459331502; $lng = 13.453662344;    # Berlin-Neukoelln, Berlin and Potsdam

# "13.3888548", "52.5170397" );
my @city = get_city( $db->city, $lat, $lng );
if ( scalar(@city) <= 0 ) {

    #push @city, "NO_CITY";
}
else {

    # areas in shortest distance first
    @city = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @city;
}

my $json = new JSON;
print $json->encode( \@city );

my $remote_host = $q->remote_host;
warn "lat: $lat, lng: $lng, city: ", join( ",", @city ), " ip: $remote_host\n"
  if $debug;

