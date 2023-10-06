#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2021 Wolfram Schneider, https://bbbike.org

BEGIN {
    system(qq[printf "quit\n" | nc localhost 4949 >/dev/null]);
    if ($?) {
        print "1..0 # no running munin daemon found, skip tests\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_FAST}
        && !-e "/usr/local/www/bbbike.org/data-osm/Hamburg/strassen" )
    {
        print "1..0 # skip due no build yet\n";
        exit;
    }

    my $logfile = "/var/log/lighttpd/bbbike.log";
    if ( !-f $logfile ) {
        print "1..0 # no $logfile found, not in production yet?\n";
        exit;
    }
}

use Test::More;
use strict;
use warnings;

my @munin_scripts = glob("/etc/munin/plugins/bbbike-*");
push @munin_scripts, glob("/etc/munin/plugins/extract-*");
plan tests => 1 + scalar(@munin_scripts) * 3;

######################################################################
# may fail if permissions are wrong, e.g. after a system upgrade
# sudo chmod o+rx /var/log/lighttpd
#
system(
qq[printf "fetch bbbike-processes\nquit\n" | nc localhost 4949 | egrep -q value]
);

my $status = $?;
if ($status) {
    system( "ls", "-ld", "/var/log/lighttpd" );
}

is( $status, 0,
    "munin bbbike-processes script is running and can read /var/log/lighttpd" );

foreach my $script (@munin_scripts) {
    is( -e $script && -x $script, 1, "munin script $script is executable\n" );
    is( system("$script config >/dev/null"),
        0, "check config: $script config\n" );
    is( system("$script >/dev/null"), 0, "check output: $script\n" );
}

__END__
