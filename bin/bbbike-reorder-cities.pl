#!/usr/local/bin/perl
# Copyright (c) 2011-2013 Wolfram Schneider, http://bbbike.org
#
# bbbike-reorder-cities.pl - re-order cities by size
#
# but not all large files first, mix the first 1/4 with smaller
# cities to avoid memory shortage

use strict;
use warnings;

my @list;
while (<>) {
    chomp;
    push @list, $_;
}

my $count = scalar(@list);
my $first = int( $count / 4 );

my %printed;
for ( my $i = 0 ; $i < $count ; $i++ ) {
    next if exists $printed{$i};
    print $list[$i], "\n";
    $printed{$i} = 1;

    if ( ( my $j = $i + $first ) < $count ) {
        next if exists $printed{$j};    # should never reached
        print $list[$j], "\n";
        $printed{$j} = 1;
    }
}

