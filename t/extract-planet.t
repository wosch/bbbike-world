#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# see also world/t/subplanet-inner.t

use Test::More;
use Data::Dumper;
use FindBin;

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
    my $path = "../planet.osm.pbf";

    my $planet = new Extract::Planet;
    is(
        "$FindBin::Bin/$path",
        $planet->normalize_dir($path),
        "normalize path $path $FindBin::Bin/$path"
    );

    my $dir = '..';
    $planet = new Extract::Planet( 'pwd' => $dir );
    is(
        "$FindBin::Bin/$dir/$path",
        $planet->normalize_dir($path),
        "normalize path $dir/$path $FindBin::Bin/$dir/$path"
    );
}

########################################################################################
#
&planet;
&normalize_dir;

__END__
