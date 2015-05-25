#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Test::More;
use Data::Dumper;
use CGI;
use JSON;

use lib qw(world/lib);
use Extract::Poly;
use Extract::Utils;

use strict;
use warnings;

my $debug = 0;

sub perl2string {
    my $perl = shift;

    return encode_json($perl);
}

######################################################################################
# wrapper functions
#
# TODO:
#  save_request
#  complete_save_request
#  normalize_polygon
#  check_queue
#  extract_coords
#  polygon_bbox;

diag("large_int()") if $debug;
is( large_int(0),           0,             "check zero" );
is( large_int(10),          10,            "check 10" );
is( large_int(10.5),        "10.5",        "check 10.5" );
is( large_int(100),         100,           "check 100" );
is( large_int(1_000),       "1,000",       "check 1,000" );
is( large_int(10_000),      "10,000",      "check 10,000" );
is( large_int(12_345.6789), "12,345.6789", "check 12,345.6789" );
is( large_int(100_000),     "100,000",     "check 100,000" );
is( large_int(1_000_000),   "1,000,000",   "check 1,000,000" );
is( large_int(10_000_000),  "10,000,000",  "check 10,000,000" );

my $poly = new Extract::Poly;

diag("is_lat()") if $debug;
is( $poly->is_lat(0),      1, "lat 50" );
is( $poly->is_lat(50),     1, "lat 50" );
is( $poly->is_lat(-50),    1, "lat -50" );
is( $poly->is_lat(90),     1, "lat 90" );
is( $poly->is_lat(-90),    1, "lat -90" );
is( $poly->is_lat(150),    0, "not lat 150" );
is( $poly->is_lat(-150),   0, "not lat -150" );
is( $poly->is_lat(179),    0, "not lat 179" );
is( $poly->is_lat(-179),   0, "not lat -179" );
is( $poly->is_lat(10150),  0, "not lat 10150" );
is( $poly->is_lat(-10150), 0, "not lat -10150" );

diag("is_lng()") if $debug;
is( $poly->is_lng(0),      1, "lng 50" );
is( $poly->is_lng(50),     1, "lng 50" );
is( $poly->is_lng(-50),    1, "lng -50" );
is( $poly->is_lng(150),    1, "not lng 150" );
is( $poly->is_lng(-150),   1, "not lng -150" );
is( $poly->is_lng(179),    1, "not lng 179" );
is( $poly->is_lng(-179),   1, "not lng -179" );
is( $poly->is_lng(180),    1, "not lng 180" );
is( $poly->is_lng(-180),   1, "not lng -180" );
is( $poly->is_lng(181),    0, "not lng 181" );
is( $poly->is_lng(-181),   0, "not lng -181" );
is( $poly->is_lng(10150),  0, "not lng 10150" );
is( $poly->is_lng(-10150), 0, "not lng -10150" );

diag("square_km()") if $debug;
is( square_km( 52.23, 12.76, 52.82, 13.98 ), 5452,  "5452 square km" );
is( square_km( 0,     0,     1,     1 ),     12366, "12366 square km" );
is( square_km( 0,     0,     0,     0 ),     0,     "0 square km" );
is( square_km( 3,     3,     3,     3 ),     0,     "0 square km" );
is( square_km( -3,    -3,    -3,    -3 ),    0,     "0 square km" );
is( square_km( -3,    -3,    -3,    3 ),     0,     "0 square km" );

diag("Param()") if $debug;
my $q = new CGI;
$q->param( "foo", 123 );
is( Param( $q, "foo" ), "123", "param 123" );
$q->param( "foo", " 123 " );
is( Param( $q, "foo" ), "123", "param space 123" );
$q->param( "foo", "[123|45 | 6] " );
is( Param( $q, "foo" ), "[123|45 | 6]", "param space [123|45 | 6]" );

diag("parse_coords()") if $debug;
my $coords = [
    [ "13.283", "52.441" ],
    [ "13.494", "52.441" ],
    [ "13.393", "52.555" ],
    [ "13.494", "52.591" ],
    [ "13.283", "52.591" ],
    [ "13.399", "52.485" ]
];

my @coords = $poly->parse_coords( encode_json($coords) );
is( perl2string($coords), perl2string( \@coords ), "parse coords from json" );

diag Dumper(\@coords) if $debug >= 2;

plan tests => 44;

__END__
