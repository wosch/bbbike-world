#!/usr/bin/perl

use Getopt::Long;

use lib qw(world/lib);
use Extract::Config;

use strict;
use warnings;

my $debug  = 1;
my $random = 1;

my $formats = $Extract::Config::formats;
my $server  = 'http://dev1.bbbike.org';
my $sw_lng = -72.211;
my $sw_lat = -13.807;
my $ne_lng = -71.732;
my $ne_lat = -13.235;


foreach my $key ( keys %$formats ) {
    print qq{curl -sSf "$server/cgi/extract.cgi}
      . qq{?sw_lng=$sw_lng&sw_lat=$sw_lat}
      . ( $random ? int( rand(1_000_000) ) : "" )
      . qq{&ne_lng=$ne_lng&ne_lat=$ne_lat}
      . ( $random ? int( rand(1_000_000) ) : "" )
      . qq{&email=Nobody&as=1.933243109431466&pg=0.9964839602712444&coords=&oi=1}
      . qq{&city=test&lang=en&submit=extract&format=$key"\0};
}

