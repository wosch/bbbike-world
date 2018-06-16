#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org
#
# test osmconvert-wrapper script

BEGIN {
    if ( $ENV{BBBIKE_TEST_FAST} && !$ENV{BBBIKE_TEST_LONG} ) {
        print "1..0 # skip due fast test\n";
        exit;
    }
}

use Test::More;
use File::Temp qw(tempfile);
use File::stat;

use strict;
use warnings;

plan 'no_plan';

my $debug      = 0;
my $poly       = 'osm/Lima/Lima.poly';
my $sub_planet = '../osm/download/sub-planet/south-america.osm.pbf';

SKIP: {
    skip "Either $poly or $sub_planet does not exists"
      if !( -e $poly && -e $sub_planet );

    my $tmpfile = File::Temp->new( UNLINK => 0, SUFFIX => ".pbf" );
    my @system = (
        "./world/bin/osmconvert-wrapper",
        "-o", $tmpfile, "-B=$poly",
        "--drop-author", "--drop-version", "--out-pbf", $sub_planet
    );

    diag( join "\n", @system ) if $debug >= 1;

    system(@system);
    is( $?, 0, "osmconvert-wrapper extracts" );

    my $st = stat($tmpfile);

    isnt( $st, undef, "tmpfile $tmpfile exists" );
    my $size = -1;

    # for whatever reasons stat() in perl return zero bytes, while other
    # tools like ls or wc works fine
    if (0) {
        $size = $st->size;
    }
    else {

        $size = `wc -c $tmpfile`;
        $size =~ s/\s+.*\n//;
    }

    my $min_size = 9_300_000;
    cmp_ok( $size, ">=", $min_size,
        "check min size $size >= $min_size: $tmpfile" );

    unlink($tmpfile);
}

__END__
