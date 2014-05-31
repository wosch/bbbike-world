#!/usr/local/bin/perl
# Copyright (c) 2011-2014 Wolfram Schneider, http://bbbike.org
#
# random-files.pl - sort arguments randomly
#
# ./random-files.pl ./t/*.t

use strict;
use warnings;

sub out {
    my @files = @_;

    print join " ", @files;
}

sub random_sort {
    my @files = @_;

    my %m = map { $_ => rand() } @files;

    return sort { $m{$a} <=> $m{$b} } keys %m;
}

&out( $ENV{BBBIKE_RANDOM_FILES} ? &random_sort(@ARGV) : @ARGV );

