#!/usr/local/bin/perl
# Copyright (c) Nov 2015 Wolfram Schneider, http://bbbike.org
#
# extract-formats.pl - test all extract formats

use lib qw(world/lib);
use Extract::Config;

use strict;
use warnings;

my $debug  = 1;
my $random = 1;

my $formats = $Extract::Config::formats;
my $server  = 'http://dev1.bbbike.org';
my $sw_lng  = -72.211;
my $sw_lat  = -13.807;
my $ne_lng  = -71.732;
my $ne_lat  = -13.235;

sub message {
    print
qq{# please run now: ./world/t/extract-formats.pl | xargs -P4 -n1 -0 /bin/sh -c >/dev/null \0};
}

sub generate_urls {

    foreach my $key ( keys %$formats ) {
        next if $key =~ /^png-/;

        print qq{curl -sSf "$server/cgi/extract.cgi}
          . qq{?sw_lng=$sw_lng&sw_lat=$sw_lat}
          . ( $random ? int( rand(1_000_000) ) : "" )
          . qq{&ne_lng=$ne_lng&ne_lat=$ne_lat}
          . ( $random ? int( rand(1_000_000) ) : "" )
          . qq{&email=Nobody&as=1.933243109431466&pg=0.9964839602712444&coords=&oi=1}
          . qq{&city=etest&lang=en&submit=extract&format=$key"\0};
    }
}

######################################################################
# main
#
&message;
&generate_urls;

1;
