#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org
#
# check map compare JS/images and external libs
#

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} || $ENV{BBBIKE_TEST_SLOW_NETWORK} ) {
        print "1..0 # skip due slow or no network\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use Encode;
use BBBike::Test;
use Extract::Config;

use strict;
use warnings;

my $test           = BBBike::Test->new();
my $extract_config = Extract::Config->new()->load_config_nocgi();

my @list = ();

my @production = $extract_config->get_server_list('production');
my @development =
  $extract_config->get_server_list(qw/www dev tile extract download api/);
my @local = $ENV{"BBBIKE_TEST_SERVER"};

my @aliases = qw(
  http://cyclerouteplanner.org
  http://cyclerouteplanner.com
);

foreach my $item ( @production, @aliases, @development, @local ) {
    my @match = ("User-agent:");

    # www.bbbike.org has a longer robots.txt
    if ( $item =~ m,^http://(www\.|localhost:), ) {
        push @match,
          ( 'Disallow: /Berlin/?', 'Disallow: /en/Berlin/?', 'Disallow: /de/' );
    }

    push @list,
      {
        'page'      => "$item/robots.txt",
        'min_size'  => 20,
        'match'     => \@match,
        'mime_type' => 'text/plain',
      };
}

my $count = 3 * scalar(@list);
foreach my $obj (@list) {
    $count += scalar( @{ $obj->{'match'} } );
}
plan tests => $count;

############################################################################
my $ua = $test->{'ua'};

foreach my $obj (@list) {
    my $url = $obj->{'page'};

    my $resp = $ua->get($url);
    ok( $resp->is_success, $url );

    my $mime_type = exists $obj->{mime_type} ? $obj->{mime_type} : "text/plain";
    is( $resp->content_type, $mime_type, "page $url is $mime_type" );

    my $content = $resp->decoded_content;
    my $length =
      defined $resp->content_length ? $resp->content_length : length($content);
    cmp_ok( $length, ">", $obj->{min_size},
        "page $url is greather than: " . $length . " > " . $obj->{min_size} );

    next if !exists $obj->{'match'};
    foreach my $match ( @{ $obj->{'match'} } ) {
        like $content, qr{$match}, qq{Found string '$match' in $url};
    }
}

__END__
