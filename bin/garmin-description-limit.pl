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

# garmin max. description byte limit of 50 (LANG=C) or 49 (LANG=en_US.UTF-8)
my $limit = $ENV{GARMIN_DESCRIPTION_LIMIT} // 49;
my $debug = $ENV{DEBUG}                    // 0;

# byte input
binmode \*STDOUT, ":raw";
binmode \*STDIN,  ":raw";

my $string = "";
while (<>) {
    $string = $_;
    last;
}

chomp($string);
if ( $string eq "" ) {
    die "usage: $0 < file\n";
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

# count every Unicode character as 4 byte (UTF-32?) for java
my $counter   = 0;
my $string_32 = "";
foreach my $c ( split( //, $final_string ) ) {
    my $bytes = encode( "UTF-8", $c );

    my $length = length($bytes);

    # non latin1 are stored as 32 bit
    $length = $length > 1 ? 4 : $length;

    if ( $counter + $length > $limit ) {
        last;
    }

    $string_32 .= $c;
    $counter += $length;
}

warn "Length final utf8/4bytes: '", encode( "UTF-8", $string_32 ), "' ",
  length($string_32), " characters\n"
  if $debug;

my $octets = encode( "UTF-8", $string_32 );
warn "Length final octets '$octets' ", length($octets), "/$counter bytes\n"
  if $debug;

# final output
print $octets;

#EOF
