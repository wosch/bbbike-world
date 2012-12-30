#!/usr/local/bin/perl
# Copyright (c) 2012-2013 Wolfram Schneider, http://bbbike.org

# Aachen:::de::5.88 50.60 6.58 50.99:294951::

my $x = shift;
$x = 0 if !defined $x;

foreach my $y ( -90 .. 89 ) {
    my $y1 = $y + 1;
    my $x1 = $x + 1;

    #print "$x,$y 1,$y1\n";
    print "planet_${x}_${y}_${x1}_${y1}:::de:other:$x $y $x1 $y1:294951::\n";
}

