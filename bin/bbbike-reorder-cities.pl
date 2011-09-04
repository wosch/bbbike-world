#!/usr/local/bin/perl

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
    $printed{$i}=1;

    if ( (my $j = $i + $first) < $count) {
    	next if exists $printed{$j}; # should never reached
    	print $list[$j], "\n";
    	$printed{$j}=1;
    }
}

