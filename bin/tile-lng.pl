#!/usr/local/bin/perl
# Copyright (c) 2012-2013 Wolfram Schneider, http://bbbike.org
#
# tile-lng.pl - split the planet.osm into 360 lng data tiles
#
# usage: tile-lng.pl > cities.csv

# Aachen:::de::5.88 50.60 6.58 50.99:294951::

my $x = shift;
$x = 0 if !defined $x;

my $step = 4;
foreach my $x ( -180 .. 179 ) {
    my $y  = -89;
    my $y1 = 89;
    my $x1 = $x + $step;

    next if $x % $step != 0;

    #print "$x,$y 1,$y1\n";
    print "planet_${x}_${y}_${x1}_${y1}:::en:other:$x $y $x1 $y1:294951::\n";
}

