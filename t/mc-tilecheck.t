#!/usr/local/bin/perl
# Copyright (c) Dec 2012 Wolfram Schneider, http://bbbike.org
#
# bbbike-org-mc-tilecheck.t - check if all tile URL images can be viewed for map compare

BEGIN {
    system( "which", "curl" );
    if ($?) {
        print "1..0 # skip no curl found, skip tests\n";
        exit;
    }

    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
}

use Test::More;
use File::stat;
use Encode;
use File::Temp qw(tempfile);

use strict;
use warnings;

plan tests => 2;
my $url_file = 'world/t/mc/tile-url.txt';

######################################################################
my ( $fh, $tempfile ) = tempfile();

my $data =
q[perl -ne 'chomp; print qq{curl --connect-timeout 10 -sSf "$_" || echo "$_" >&2 \0} if !/^\s*#/' ]
  . qq[$url_file | xargs -0 -n1 -P2 /bin/sh -c > $tempfile];
system($data);
is( $?, 0, "Map Compare: tested all tile images" );

my $st = stat($tempfile);
cmp_ok( $st->size, '>', 1_680_000, 'Got enough image tile data' );

unlink $tempfile;

__END__
