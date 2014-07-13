#!/usr/local/bin/perl -MDevel::Size=total_size
# Copyright (c) 2011-2013 Wolfram Schneider, http://bbbike.org
#
# bbbike-perf.pl - check perl memory / cpu usage of a city

use List::Util qw(sum);
use Data::Dumper;

#use lib "./lib"; #use BBBikeXS;
use Strassen;
use Strassen::StrassenNetz;

use strict;
use warnings;

my $c1 = "7.75805,48.55754";
my $c2 = "7.75469,48.59023";

#StrassenNetz::use_data_format( $ENV{i} );

my $net = StrassenNetz->new( Strassen->new("strassen") );
$net->make_net;
print int( total_size($net) / 1024 / 1024 * 10 ) / 10, " MB\n";

my ($path) = $net->search( $c1, $c2, WideSearch => 0 );
my (@route) = $net->route_to_name($path);
my $dist1 = int sum map { $_->[StrassenNetz::ROUTE_DIST] } @route;
print "dist: ", int( $dist1 / 100 ) / 10, " km\n";

#print Dumper(\@route);
