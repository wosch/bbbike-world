#!/usr/local/bin/perl
# Copyright (c) 2024-2024 Wolfram Schneider, https://bbbike.org
#
# garmin-description-limit.pl - limit description for garmin to 50 bytes
#                               regardless the number of characters
#

use Encode qw(encode decode);
use utf8;

use strict;
use warnings;

# garmin max. description byte limit
my $limit = $ENV{GARMIN_DESCRIPTION_LIMIT} // 50;
my $debug = 1;

# byte input
binmode \*STDOUT, ":raw";
binmode \*STDIN,  ":raw";

my $string;
while (<>) {
    $string = $_;
    last;
}
$string //= "";
chomp($string);

if ( $string eq "" ) {
    die "usage: $0 string\n";
}

# $string = "北京中轴线 osm/latin1 BBBike.org 18-Aug-2024";
warn "Length octet string '$string' ", length($string), " bytes\n" if $debug;

# Limit the string to NN bytes
my $limited_string = substr( $string, 0, $limit );
warn "Limited octet string (max $limit octets) '$limited_string' ",
  length($limited_string), " bytes\n"
  if $debug;

# Decode back to a UTF-8 string, ignore UTF-8 last character errors
my $final_string = decode( "UTF-8", $limited_string, Encode::FB_QUIET );
warn "Length final utf8: '", encode( "UTF-8", $final_string ), "' ",
  length($final_string), " characters\n"
  if $debug;

my $octets = encode( "UTF-8", $final_string );
warn "Length final octets '$octets' ", length($octets), " bytes\n" if $debug;

# final output
print $octets;

#EOF
