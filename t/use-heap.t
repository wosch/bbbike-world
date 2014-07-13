#!/usr/local/bin/perl
# Copyright (c) July 2014 Wolfram Schneider, http://bbbike.org
# 
# check if $use_heap is working

BEGIN { }

use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
    "$FindBin::RealBin", "lib");

use Devel::Size qw(total_size);
use List::Util qw(sum);
use Data::Dumper;

use Test::More "no_plan";
use Time::HiRes qw( gettimeofday tv_interval );
use IO::File;

use Strassen;
use Strassen::StrassenNetz;

use strict;
use warnings;

my $file = 'world/t/start-dest-points.txt';
my $debug = 1;
my $net;
my %time;

sub init {
$net = StrassenNetz->new( Strassen->new("strassen") );
isnt($net, undef, "got net");

$net->make_net;
my $size = int( total_size($net) / 1024 / 1024 * 10 ) / 10;

cmp_ok( $size, '>', 10, "network size $size > 10" );

diag "memory usage: $size MB\n";
}

sub heap_test {
    my $c1 = shift;
    my $c2 = shift;

    warn "Start: $c1, Dest: $c2\n" if $debug >= 2;

    my @result;
    foreach my $heap ( 0, 1 ) {
        my $t0 = [gettimeofday];

        $StrassenNetz::use_heap = $heap;
        my ($path) = $net->search( $c1, $c2, WideSearch => 0 );
        my (@route) = $net->route_to_name($path);
        my $dist1 = int sum map { $_->[StrassenNetz::ROUTE_DIST] } @route;
        diag "dist: ", int( $dist1 / 100 ) / 10, " km\n" if $debug >= 2;
		     my $elapsed = tv_interval ( $t0 );
	diag "time: $elapsed\n" if $debug >= 2;
	$time{$heap} += $elapsed;

        push @result, \@route;

        warn Dumper( \@route ) if $debug >= 3;
    }

    is_deeply( $result[0], $result[1] );
}

sub run_searches {
my $counter = 0;
my $fh = new IO::File $file, "r";
while (<$fh>) {
    chomp;
    next if /^\s*#/;

    my ( $c1, $c2 ) = split " ";
    next if !($c1 && $c2);

    heap_test( $c1, $c2 );
    $counter++;
}
return $counter;
}

&init;
my $counter = &run_searches;

if ($debug) {
print "\n";
foreach my $key (0, 1) {
   diag "Total   time spend in heap '$key': ", $time{$key}, " sec\n";
   diag "average Time spend in heap '$key': ", $time{$key}/$counter, " sec\n";
}

diag "Speed up: ", $time{"0"}/$time{"1"}, "\n";
}


1;

