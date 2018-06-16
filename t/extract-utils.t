#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use Data::Dumper;
use CGI;
use JSON;

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
#
#  normalize_polygon
#  check_queue
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

diag("square_km()") if $debug;
is( square_km( 52.23, 12.76, 52.82, 13.98 ), 5452,  "5452 square km" );
is( square_km( 0,     0,     1,     1 ),     12366, "12366 square km" );
is( square_km( 0,     0,     0,     0 ),     0,     "0 square km" );
is( square_km( 3,     3,     3,     3 ),     0,     "0 square km" );
is( square_km( -3,    -3,    -3,    -3 ),    0,     "0 square km" );
is( square_km( -3,    -3,    -3,    3 ),     0,     "0 square km" );

diag("file_mtime_diff()") if $debug;
my $utils = new Extract::Utils;
is( $utils->file_mtime_diff( $0, $0 ), 0, "file mtime diff" );

plan tests => 17;

__END__
