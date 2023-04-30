#!/usr/local/bin/perl
# Copyright (c) July 2014-2018 Wolfram Schneider, https://bbbike.org
#
# check if $use_heap is working

BEGIN {
    use FindBin;
    use lib (
        "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
        "$FindBin::RealBin",    "lib",
        "."
    );

    chdir("$FindBin::RealBin/../..")
      or die "Cannot find bbbike world root directory\n";
}

use Devel::Size qw(total_size);
use List::Util qw(sum);
use Data::Dumper;

use Test::More;
use Time::HiRes qw( gettimeofday tv_interval );
use IO::File;

use Strassen;
use Strassen::StrassenNetz;

use strict;
use warnings;

my $file  = $ENV{BBBIKE_START_DEST_POINTS} || 'world/t/start-dest-points.txt';
my $debug = 0;
my $WideSearch = 0;
my $max        = $ENV{BBBIKE_TEST_LONG} ? 100 : $ENV{BBBIKE_TEST_FAST} ? 5 : 20;

my $net;
my %time;
my %dist;
my %extra_args;

sub extra_args_cat {
    my $type = shift;
    my $t0   = [gettimeofday];

    my $penalty_N1 = {
        "B"  => 1.5,
        "HH" => 1.5,
        "H"  => 1.5,
        "NH" => 1,
        "N"  => 1,
        "NN" => 1
    };

    my $penalty_N2 = {
        "B"  => 4,
        "HH" => 4,
        "H"  => 4,
        "NH" => 2,
        "N"  => 1,
        "NN" => 1
    };

    my $penalty =
        $type eq 'N1' ? $penalty_N1
      : $type eq 'N2' ? $penalty_N2
      :                 {};

    my $str        = get_streets();
    my $strcat_net = new StrassenNetz $str;
    $strcat_net->make_net_cat( -usecache => 1 );

    my %extra_args;

    $extra_args{Strcat} = {
        Net     => $strcat_net,
        Penalty => $penalty,
    };

    my $elapsed = tv_interval($t0);
    diag "extra_args_cat(): $elapsed sec\n" if $debug >= 1;
    return %extra_args;
}

sub extra_args_quality {
    my $type = shift;
    my $t0   = [gettimeofday];

    my $penalty_Q2 = {
        "Q0" => 1,
        "Q1" => 1,
        "Q2" => 1.5,
        "Q3" => 1.8
    };

    my $penalty = $type eq 'Q2' ? $penalty_Q2 : {};

    my $qualitaet_net = new StrassenNetz( Strassen->new("qualitaet_s") );
    $qualitaet_net->make_net_cat( -usecache => 1 );

    my %extra_args;

    $extra_args{Qualitaet} = {
        Net     => $qualitaet_net,
        Penalty => $penalty,
    };

    my $elapsed = tv_interval($t0);
    diag "extra_args_quality(): $elapsed sec\n" if $debug >= 1;
    return %extra_args;
}

sub init {
    my $t0 = [gettimeofday];
    $net = StrassenNetz->new( Strassen->new("strassen") );
    my $elapsed = tv_interval($t0);
    diag "Strassen->new('strassen'): $elapsed sec\n" if $debug >= 1;

    isnt( $net, undef, "got net" );

    $t0 = [gettimeofday];
    $net->make_net;
    $elapsed = tv_interval($t0);
    diag "make_net: $elapsed sec\n" if $debug >= 1;

    my $size = int( total_size($net) / 1024 / 1024 * 10 ) / 10;

    cmp_ok( $size, '>', 10, "network size $size > 10" );

    diag "memory usage: $size MB\n" if $debug >= 1;
}

sub heap_test {
    my $c1 = shift;
    my $c2 = shift;

    diag "Start: $c1, Dest: $c2\n" if $debug >= 2;

    my @result;
    foreach my $heap ( 0, 1 ) {
        my $t0 = [gettimeofday];

        $StrassenNetz::use_heap = $heap;

        # check if coordinates are valid
        for ( $c1, $c2 ) {
            if ( !$net->reachable($_) ) {
                my $new = $net->fix_coords($_);
                diag "correct coords $file: $_ => $new" if $debug >= 1;
                $_ = $new;
                next;
            }
        }

        my ($path) =
          $net->search( $c1, $c2, WideSearch => $WideSearch, %extra_args );
        my (@route) = $net->route_to_name($path);
        my $dist1 = int sum map { $_->[StrassenNetz::ROUTE_DIST] } @route;
        diag "dist: ", int( $dist1 / 100 ) / 10, " km\n" if $debug >= 2;
        my $elapsed = tv_interval($t0);
        diag "time: $elapsed\n" if $debug >= 2;
        $time{$heap} += $elapsed;
        $dist{$heap} += $dist1;

        push @result, \@route;

        diag Dumper( \@route ) if $debug >= 3;
    }

    is_deeply( $result[0], $result[1] );
}

sub run_searches {
    my $counter = 0;
    my $fh      = new IO::File $file, "r";
    while (<$fh>) {
        chomp;
        next if /^\s*#/;

        my ( $c1, $c2 ) = split " ";
        next if !( $c1 && $c2 );

        heap_test( $c1, $c2 );
        $counter++;

        last if $counter >= $max;
    }
    return $counter;
}

sub get_streets {
    return new Strassen "strassen";
}

####################################################################
#

my $quality = 'Q2';
foreach my $type ( '', 'N1', 'N2' ) {
    foreach my $q ( '', 'Q2' ) {

        &init;
        %extra_args = ( &extra_args_cat($type), &extra_args_quality($q) );

        # reset stat
        %time = ();
        %dist = ();

        my $counter = &run_searches;

        if ($debug) {
            diag "Preferred street category: '$type', quality: '$q'\n";

            foreach my $key ( 1, 0 ) {
                diag "  total time spend in heap '$key': ", $time{$key},
                  " sec\n";
                diag "average time spend in heap '$key': ",
                  $time{$key} / $counter,
                  " sec\n";

                diag "  total dist spend in heap '$key': ",
                  int( $dist{$key} / 100 ) / 10, " km\n";
                diag "average dist spend in heap '$key': ",
                  ( int( $dist{$key} / 100 ) / $counter ) / 10, " km\n";
            }

            diag "Speed up: ", $time{"0"} / $time{"1"}, "\n";
        }
    }
}

done_testing;

1;

