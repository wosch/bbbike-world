#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN {
    system(qq[printf "quit\n" | nc localhost 4949 >/dev/null]);
    if ($?) {
        print "1..0 # no running munin daemon found, skip tests\n";
        exit;
    }
}

use Test::More;
use strict;
use warnings;

plan tests => 1;

######################################################################
# may fail if permissions are wrong, e.g. after a system upgrade
# sudo chmod o+rx /var/log/lighttpd
#
system(
    qq[printf "fetch bbbike-route\nquit\n" | nc localhost 4949 | egrep -q value]
);

is( $?, 0, "munin bbbike script is running" );

__END__
