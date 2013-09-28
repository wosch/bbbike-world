#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

# Author: Slaven Rezic

# configure city to test
BEGIN {
    my $city = "SanFrancisco";

    $ENV{BBBIKE_DATADIR} = $ENV{DATA_DIR} = "data-osm/$city";
    my $hoehe = "$ENV{BBBIKE_DATADIR}/hoehe";

    if ( !-e $hoehe ) {
        print "1..0 # skip '$hoehe' does not exists\n";
        print qq{       please run: make CITIES="$city" fetch convert\n};
        exit;
    }
    if (1) {
        print "1..0 # skip due Deep recursion on anonymous subroutine\n";
        exit;
    }
}

use FindBin;
use lib (
    "$FindBin::RealBin/..",      "$FindBin::RealBin/../lib",
    "$FindBin::RealBin/../data", "$FindBin::RealBin",
);

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Storable qw(dclone);
use Test::More;
use List::Util qw(sum);
use Time::HiRes qw/gettimeofday tv_interval/;

use Strassen::Core;
use Strassen::Util;
use Strassen::Lazy;
use Strassen::StrassenNetz;
use Route;
use Route::Heavy;
use BBBikeElevation;

use BBBikeTest;

use strict;
use warnings;

#plan tests => 50;
plan tests => 1;
my $debug = 2;

my $s     = Strassen::Lazy->new("strassen");
my $s_net = StrassenNetz->new($s);
$s_net->make_net();    # UseCache => 1 );

{
    local $Data::Dumper::Indent = 0;
    my $enable_dist = 1;

    my $e = new BBBikeElevation;
    $e->init;

    if ( $debug >= 3 ) {
        open OUT, "> /tmp/net.old" or die "$!\n";
        print OUT Dumper($s_net);
    }

    my $extra_args = $e->elevation_net;
    if ( $debug >= 3 ) {
        open OUT, "> /tmp/net.hoehe" or die "$!\n";
        print OUT Dumper( $extra_args->{Steigung}{Net} );
    }
    print $e->statistic, "\n" if $debug;

    my ( $c1, $c2 );
    if ( $ENV{BBBIKE_DATADIR} && -f "$ENV{DATA_DIR}/strassen" ) {
        pass("-- Marine Drive - Channel Street --");

        # data-osm/SanFrancisco
        $c1 = "-122.4715,37.80851";     # Marine Drive
        $c2 = "-122.39178,37.77455";    # Channel Street

    }
    else {
        pass("-- no city defined, fall back to bbbike --");
        pass("-- Scharnweber - Lichtenrader Damm --");
        $c1 = "4695,17648";             # Scharnweberstr.
        $c2 = "10524,655";              # Lichtenrader Damm
    }

    my $net = $s_net;
    foreach my $args ( {}, $extra_args ) {
        my $t0 = [gettimeofday];

        print "Start =>\n";
        for my $c ( $c1, $c2 ) {        # points may move ... fix it!
            $c = $net->fix_coords($c);
        }

        my ($path) = $net->search( $c1, $c2, %$args );
        my (@route) = $net->route_to_name($path);

        if ($enable_dist) {
            my $dist1 = int sum map { $_->[StrassenNetz::ROUTE_DIST] } @route;

            print "Distance: $dist1 meters\n";
            print "Hops: ", scalar(@route), "\n";
        }

        print Dumper( \@route ), "\n";
        my ( $up, $down ) = $e->altitude_difference($path);
        print "Up: $up meters, down: $down meters, total: ", $up + $down,
          " meters\n";

        print Dumper($path) if $debug >= 3;

        printf "Search time: %.3f seconds\n\n",
          tv_interval( $t0, [gettimeofday] );
    }
}

__END__
