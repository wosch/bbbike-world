#!/usr/local/bin/perl
# Copyright (c) 2011-2014 Wolfram Schneider, https://bbbike.org
#
# bbbike-perf.pl - check perl memory / cpu usage of a city

use Devel::Size qw(total_size);
use List::Util qw(sum);
use Data::Dumper;

use lib "./lib";    #use BBBikeXS;
use Strassen;
use Strassen::StrassenNetz;
use Test::More "no_plan";
use Time::HiRes qw( gettimeofday tv_interval
  stat );

use strict;
use warnings;

my $debug = 1;

my $net = StrassenNetz->new( Strassen->new("strassen") );
$net->make_net;
print int( total_size($net) / 1024 / 1024 * 10 ) / 10, " MB\n";

my %time;

sub heap_test {
    my $c1 = shift;
    my $c2 = shift;

    warn "Start: $c1, Dest: $c2\n" if $debug;

    my @result;
    foreach my $heap ( 0, 1 ) {
        my $t0 = [gettimeofday];

        $StrassenNetz::use_heap = $heap;
        my ($path) = $net->search( $c1, $c2, WideSearch => 0 );
        my (@route) = $net->route_to_name($path);
        my $dist1 = int sum map { $_->[StrassenNetz::ROUTE_DIST] } @route;
        print "dist: ", int( $dist1 / 100 ) / 10, " km\n";
        my $elapsed = tv_interval($t0);
        print "time: $elapsed\n";
        $time{$heap} += $elapsed;

        push @result, \@route;

        #print Dumper( \@route );
    }

    is_deeply( $result[0], $result[1] );
}

my $counter = 0;
while (<>) {
    chomp;
    my ( $c1, $c2 ) = split " ";
    heap_test( $c1, $c2 );
    $counter++;
}

print "\n";
foreach my $key ( 0, 1 ) {
    print "Total   time spend in heap '$key': ", $time{$key}, " sec\n";
    print "average Time spend in heap '$key': ", $time{$key} / $counter,
      " sec\n";
}

print "Speed up: ", $time{"0"} / $time{"1"}, "\n";

