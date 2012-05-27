#!/usr/local/bin/perl

# Aachen:::de::5.88 50.60 6.58 50.99:294951::

my $x = shift;
$x = 0 if !defined $x;

foreach my $x ( -180 .. 179 ) {
    my $y = -89;
    my $y1 = 89;
    my $x1 = $x + 1;

    #print "$x,$y 1,$y1\n";
    print "p_${x}_${y}_${x1}_${y1}:::de:other:$x $y $x1 $y1:294951::\n";
}


