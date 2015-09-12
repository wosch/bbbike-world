#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

use Test::More;
use JSON;
use lib qw(./world/lib ../lib);
use BBBike::Test;
use Extract::Config;

my $test = BBBike::Test->new();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages =
  qw[ http://extract.bbbike.org http://extract2.bbbike.org http://dev1.bbbike.org http://dev2.bbbike.org];
if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

my $formats = $Extract::Config::formats;

plan tests => scalar( keys %$formats ) *
  scalar(@homepages) *
  ( $test->myget_counter + 2 );

#plan 'no_plan';

sub page_check {
    my $home_url   = shift;
    my $script_url = shift
      || "$home_url/cgi/tile-size.cgi?lat_sw=51.775&lng_sw=11.995&lat_ne=53.218&lng_ne=14.775";

    my %size;
    foreach my $f ( keys %$formats ) {
        my $res = $test->myget( "$script_url&format=$f", 11 );

        # {"size": 65667.599 }
        # {"size": 0 }

        my $obj = from_json( $res->decoded_content );
        like( $obj->{"size"}, qr/^[\d\.]+$/,
            "format: $f, size: $obj->{'size'}" );

        # no two formats should have the same size
        # otherwise we may have forgotten to configure a format
        is( $size{ $obj->{'size'} },
            undef,
            "format: $f match size $obj->{'size'} of $size{$obj->{'size'}}" );

        $size{ $obj->{'size'} } = $f;
    }
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{
    &page_check($home_url);
}

__END__
