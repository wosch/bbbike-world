#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, https://bbbike.org
#
# see also world/t/subplanet-inner.t

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Planet;

use strict;
use warnings;

plan tests => 3;
my $debug = 1;

our $option;

sub planet {
    my $planet = new Extract::Planet;

    isnt( $planet, undef, "planet" );
}

sub normalize_dir {
    my $path = "planet-latest.osm.pbf";

    my $planet = new Extract::Planet;
    is( "$path", $planet->normalize_dir($path), "normalize path $path $path" );

    my $dir = '../../../osm/download';
    $planet = new Extract::Planet( 'pwd' => $dir );
    is(
        "$dir/$path",
        $planet->normalize_dir($path),
        "normalize path $dir/$path"
    );
}

########################################################################################
#
&planet;
&normalize_dir;

__END__
