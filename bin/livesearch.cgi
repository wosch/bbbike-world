#!/usr/bin/perl

use strict;
use warnings;

use CGI;

my $q = new CGI;

my $stat_file = "/tmp/log.html.$$";
system(
"env HOME=/home/wosch max_pictures=128 log_html=$stat_file logfiles=bbbike.log /home/wosch/bin/bbbike-log"
);

print $q->header();

open( STAT, $stat_file ) or die "open $stat_file: $!\n";
while (<STAT>) {
    print;
}

close STAT;

unlink($stat_file);

exit 0;

