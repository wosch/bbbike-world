#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_FAST} && !$ENV{BBBIKE_TEST_LONG} ) {
        print "1..0 # skip due fast test\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use BBBike::Test;

use strict;
use warnings;

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );

my @homepages_production = qw[
  https://extract-pro.bbbike.org
  https://extract-pro1.bbbike.org
  https://extract-pro4.bbbike.org
];

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages_production = ();
}

my $test = BBBike::Test->new();
my $counter_production =
  scalar(@homepages_production) * $test->myget_401_counter * 3;
my $counter_localhost =
  scalar(@homepages_localhost) *
  ( $test->myget_500_counter + 2 * $test->myget_head_counter );
plan tests => $counter_production + $counter_localhost;

sub page_check_401 {
    my $home_url = shift;

    $test->myget_401($home_url);
    $test->myget_401("$home_url/robots.txt");
    $test->myget_401("$home_url/cgi/extract.cgi");
}

sub page_check_500 {
    my $home_url = shift;

    $test->myget_head("$home_url/cgi/extract.cgi?pro=");
    $test->myget_head("$home_url/cgi/extract.cgi?proXXX=");
    $test->myget_500( "$home_url/cgi/extract.cgi?pro=foobar",
        "520 Unknown code" );
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (@homepages_production) {
    &page_check_401($home_url);
}

foreach my $home_url (@homepages_localhost) {
    &page_check_500($home_url);
}

__END__
