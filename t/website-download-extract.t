#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }

    if ( $ENV{BBBIKE_TEST_FAST} ) { print "1..0 # skip due fast test\n"; exit; }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use BBBike::Test;

use strict;
use warnings;

my $test = BBBike::Test->new();
my $debug = $ENV{DEBUG} || 0;

my @production = qw(
  https://download3.bbbike.org
  https://download4.bbbike.org
);

my @homepages = "https://download.bbbike.org";
if ( !$ENV{BBBIKE_TEST_FAST} ) {
    push @homepages, @production;
}

sub get_extract_files {
    my $url  = shift;
    my $data = `lynx -dump $url`;
    my @urls = ();

    my @data = split $", $data;
    foreach my $line (@data) {
        if ( $line =~ m,(https://download[0-9]\.bbbike.org/osm/extract/\S+), ) {
            my $url = $1;
            next if $url =~ /\?/;

            push @urls, $url;
        }
    }

    return @urls;
}

my @urls;
foreach my $home (@homepages) {
    push @urls, get_extract_files("$home/osm/extract/");
}

# ads only on production system
plan tests => $test->myget_counter * scalar(@urls);

sub myget_headXXX {
    my $url  = shift;
    my $size = shift;

    $size = 0 if !defined $size;

    my $req = HTTP::Request->new( HEAD => $url );
    my $res = $test->{'ua'}->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200, $url" );

    my $content_length = $res->content_length;

    # RFC2616
    if ( !defined $content_length ) {
        diag "Content length is not defined, empty file? $url\n";
        $content_length = $size + 1;
    }

    #diag("content_length: " . $content_length);
    cmp_ok( $content_length, ">", $size, "greather than $size" );

    return $res;
}

########################################################################
# main
#

diag( "extract downloads URLs to check: " . scalar(@urls) ) if $debug;
foreach my $u (@urls) {
    diag("URL: $u") if $debug >= 2;

    my $size = $u =~ /\.osm\.(gz|xz|csv\.xz|pbf)$/ ? 150 : 1_000;
    $test->myget_head( $u, $size );
}

__END__
