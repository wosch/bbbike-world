#!/usr/local/bin/perl -i
# Copyright (c) 2014-2016 Wolfram Schneider, http://bbbike.org
#
# garmin-marine-header - set header for garmin marine devices
#
# 1. find the string "GARMIN TRE"
# 2. move forward 56 characters
# 3. replace to chracters, 0x04 and 0x17
#
# Note: the header may appears several times in the gmapsupp.img

binmode \*STDIN,  ":bytes";
binmode \*STDOUT, ":bytes";

while (<>) {
    # match the magic HEADER field
    if (/GARMIN TRE....$/) {
        print;

	# move forward 51 bytes
        for ( 1 .. 51 ) {
            print getc( \*ARGV );
        }

	# set the new 2 bytes
        printf( "%c%c", 4, 23 );

	# skip the old 2 bytes
        for ( 1 .. 2 ) { 
		getc( \*ARGV ) 
	}
    }

    else {
        print;
    }
}

# EOF
