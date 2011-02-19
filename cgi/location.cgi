#!/usr/bin/perl

use CGI qw/-utf-8/;
use IO::File;

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

    foreach my $city ( keys %{$hash} ) {
        my @coord = split( /\s+/, $hash->{$city}{"coord"} );
        if ( point_in_grid( $lng, $lat, @coord ) ) {
            return $city;
        }
    }
}

##############################################################################################
#
# main
#

my $db = BBBikeWorldDB->new( 'database' => $database );

print $q->header(
    -type   => 'application/json;charset=UTF-8',
    -expire => '+5m'
);

my $lat = $q->param('lat');
my $lng = $q->param('lng');

# "13.3888548", "52.5170397" );
my $city = get_city( $db->city, $lat, $lng );

$city = "NO_CITY" if !$city;
print <<EOF;
{ "city": "$city", "street":"", "corner":"" }
EOF

warn "lat: $lat, lng: $lng, city: $city\n" if $debug;

