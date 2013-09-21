#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN { }

use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
    "$FindBin::RealBin", );

use Test::More;

use strict;
use warnings;

my @program = qw(world/bin/bbbike-build-runtime
  world/bin/bbbike-build-runtime-perl.pl
  world/bin/bbbike-build-runtime-perl-devel.pl
);

plan tests => scalar(@program);

######################################################################
#
foreach my $prog (@program) {
    system($prog);
    is( $?, 0, "$prog" );
}

__END__
