#!/usr/local/bin/perl
# Copyright (c) Sep 2018-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
    if ( $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "0..0 # skip some test due slow network\n";
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use Test::More::UTF8;
use BBBike::Test;
use Extract::Config;

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @homepages_localhost =
  ( $ENV{BBBIKE_TEST_SERVER} ? $ENV{BBBIKE_TEST_SERVER} : "http://localhost" );
my @homepages = $extract_config->get_server_list(qw/extract dev/);

if ( $ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
    @homepages = ();
}
unshift @homepages, @homepages_localhost;

sub route_check {
    my %args = @_;

    my $home_url = $args{"home_url"};
    my $route    = $args{"route"} // "";
    my $fail     = $args{"fail"} // 0;
    my $bbox     = $args{"bbox"};

    my $script_url = "$home_url/cgi/route.cgi";

    if ( $route ne "" ) {
        $script_url .= "?route=" . $route;
    }

    my $res = $test->myget_302($script_url);

    my $location = $res->header("Location");

    #diag "location: $location $script_url";

    my $command = $fail ? "unlike" : "like";

    &$command(
        $location,
        qr[https://extract[0-9]?\.bbbike\.org\?],
        "redirect to extract.cgi: $script_url"
    );
}

#############################################################################
# main
#

# check a bunch of homepages
foreach my $home_url (
    $ENV{BBBIKE_TEST_SLOW_NETWORK} ? @homepages_localhost : @homepages )
{
    # local cache
    &route_check( "home_url" => $home_url );
    &route_check( "home_url" => $home_url, "route" => "fjurfvdctnlcmqtu" );

    # fake
    &route_check(
        "home_url" => $home_url,
        "route"    => "XXXfjurfvdctnlcmqtu",
        "fail"     => 1
    );

    # to short id
    &route_check( "home_url" => $home_url, "route" => "XXX", "fail" => 1 );

    # web fetch
    &route_check( "home_url" => $home_url, "route" => "uuwfflkzmvudvzgs" );
}

done_testing;

__END__
