#!/usr/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

use Test::More;
use strict;
use warnings;

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_FAST} ) {
        print "1..0 # skip due fast test\n";
        exit;
    }
}

use LWP;
use LWP::UserAgent;

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my @homepages_localhost = ();
my @homepages           = qw[
  http://extract-pro.bbbike.org
];

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

use constant MYGET => 3;
plan tests         => scalar(@homepages) * 3 * MYGET;

my $ua = LWP::UserAgent->new;
$ua->agent("BBBike.org-Test/1.0");

sub myget_401 {
    my $url  = shift;
    my $size = shift;

    $size = 300 if !defined $size;

    my $req = HTTP::Request->new( GET => $url );
    my $res = $ua->request($req);

    isnt( $res->is_success, undef, "$url is success" );
    is(
        $res->status_line,
        "401 Unauthorized",
        "status code 401 Unauthorized - great!"
    );

    my $content = $res->decoded_content();
    cmp_ok( length($content), ">", $size, "greather than $size for URL $url" );

    return $res;
}

sub page_check {
    my $home_url = shift;

    myget_401($home_url);
    myget_401("$home_url/robots.txt");
    myget_401("$home_url/cgi/extract.cgi");
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (@homepages) {
    &page_check($home_url);
}

__END__
