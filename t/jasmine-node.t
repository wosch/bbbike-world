#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN {
    system( "which", "jasmine-node" );
    if ($?) {
        print "1..0 # skip no node.js / jasmine-node found, skip tests\n";
        exit;
    }
}

use Test::More;
use File::stat;

use strict;
use warnings;

plan tests => 1;

######################################################################
system(qq[make -s jasmine-node]);
is( $?, 0, "All JavqScript passed the jasmine-node tests" );

__END__
