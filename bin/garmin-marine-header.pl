#!/usr/local/bin/perl -i
# Copyright (c) 2016-2016 Wolfram Schneider, https://bbbike.org
#
# garmin-marine-header - set header for garmin marine devices
#
# Edit in place a garmin image:
#
# 1. find the string "GARMIN TRE"
# 2. move forward 56 bytes
# 3. replace two bytes, 0x04 and 0x17
#
# Note: the header may appears several times in the gmapsupp.img
#
# As a reference, see
# https://github.com/OpenSeaMap/garmin/blob/master/gmarine/src/Gmarine.java
#

use strict;
use warnings;

use open IN => ":bytes", OUT => ":bytes";

while (<>) {

    # match the magic HEADER field
    if (/GARMIN TRE....$/) {

        # write out
        print;

        # move forward 51 bytes
        for ( 1 .. 51 ) {
            print getc( \*ARGV );
        }

        # set the new 2 bytes
        printf( "%c%c", 4, 23 );

        # skip the old 2 bytes
        for ( 1 .. 2 ) {
            getc( \*ARGV );
        }
    }

    # write out
    else {
        print;
    }
}

# EOF
