#!/usr/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use utf8;
use Test::More;
use LWP;
use LWP::UserAgent;

use strict;
use warnings;

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }

    if ( $ENV{BBBIKE_TEST_FAST} ) { print "1..0 # skip due fast test\n"; exit; }
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";
my $debug = 0;

my @homepages = "http://download.bbbike.org";
if ( !$ENV{BBBIKE_TEST_FAST} ) {
    push @homepages,
      qw|http://download1.bbbike.org http://download2.bbbike.org|;
}

sub get_extract_files {
    my $url  = shift;
    my $data = `lynx -dump $url`;
    my @urls = ();

    my @data = split $", $data;
    foreach my $line (@data) {
        if ( $line =~ m,(http://\S+), ) {
            push @urls, $1;
        }
    }

    return @urls;
}

use constant MYGET => 3;

my @urls;
foreach my $home (@homepages) {
    push @urls, get_extract_files("$home/osm/extract/");
}

# ads only on production system
plan tests => MYGET * scalar(@urls);

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget_head {
    my $url  = shift;
    my $size = shift;

    $size = 1 if !defined $size;

    my $req = HTTP::Request->new( HEAD => $url );
    my $res = $ua->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is( $res->status_line, "200 OK", "status code 200" );

    my $content_length = $res->content_length;

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
    myget_head($u);
}

__END__
