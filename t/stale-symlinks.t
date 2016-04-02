#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use Test::More;

use strict;
use warnings;

plan tests => 1;

my $prog =
q[ find . -type l -print0 | perl -0e 'while(<>) { next if m,^\./tmp/,; if (! -e $_) { print "$_\n"; $exit=1}}; exit $exit' ];
system($prog);
is( $?, 0, "stale symlinks" );

__END__
