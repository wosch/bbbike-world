#!/usr/local/bin/perl
# Copyright (c) Aug 2015-2015 Wolfram Schneider, http://bbbike.org

BEGIN {
    if (!$ENV{BBBIKE_TEST_INTERACTIVE_FULL}) {
        print "1..0 # BBBIKE_TEST_INTERACTIVE_FULL not set, skip tests\n";
        exit;
    }
}

use Test::More;
use strict;
use warnings;

plan tests => 2;

######################################################################
# may fail if permissions are wrong, e.g. after a system upgrade
# sudo chmod o+rx /var/log/lighttpd
#
system( qq[./world/t/git-checkout-bootstrap.sh]);
is( $?, 0, "checkout runs fine" );

delete $ENV{BBBIKE_TMPDIR};
delete $ENV{BBBIKE_TMPFS};

system( qq[./world/t/git-checkout-bootstrap.sh]);
is( $?, 0, "checkout runs fine without setting BBBIKE_TMPDIR BBBIKE_TMPFS" );

__END__
