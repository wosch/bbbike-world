#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# test script to check which sub-planets can be used
#
# /this/script ./extract/trash/*.json
#
use JSON;
use Data::Dumper;

use lib qw(world/lib ../lib);
use Extract::Utils;
use Extract::Planet;

use strict;
use warnings;

my $debug = 0;
my $planet = new Extract::Planet( 'debug' => $debug );

#############################################
# main
#

binmode( \*STDOUT, ":utf8" );
my $extract_utils = new Extract::Utils;
die "No file given\n" if !@ARGV;

foreach my $file (@ARGV) {
    my $obj = $extract_utils->parse_json_file($file);
    next if !exists $obj->{"coords"} or ref $obj->{"coords"} ne 'ARRAY';

    warn Dumper($obj) if $debug >= 2;

    printf(
        "%s\t%s\t%s\n",
        $file,
        $obj->{"city"},
        $planet->get_smallest_planet_file(
            'obj'        => $obj,
            'planet_osm' => $obj->{"planet_osm"}
        )
    );
}

__END__
