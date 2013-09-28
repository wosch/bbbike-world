#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use Test::More;
use File::stat;

use strict;
use warnings;

plan tests => 1;

######################################################################
system(qq[make -s perlcheck]);
is( $?, 0, "All perl scripts and modules passed the syntax check" );

__END__
