#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2014 Wolfram Schneider, http://bbbike.org

use LWP::UserAgent;
use Test::More;

use strict;
use warnings;

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
}

binmode \*STDOUT, "utf8";
binmode \*STDERR, "utf8";

my @list = (
    {
        'page'     => 'http://www.bbike.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'http://bbike.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    {
        'page'     => 'http://mc.bbike.org/mc/',
        'min_size' => 300,
        'match'    => [ "</html>", ">Map Compare<" ]
    },

    {
        'page'     => 'http://www.cyclerouteplanner.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'http://cyclerouteplanner.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    {
        'page'     => 'http://www.cyclerouteplanner.com',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'http://cyclerouteplanner.com',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    {
        'page'     => 'http://www.cycleroute.net',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'http://cycleroute.net',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    {
        'page'     => 'http://extract.bbike.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
);

my $count = 3 * scalar(@list);
foreach my $obj (@list) {
    $count += scalar( @{ $obj->{'match'} } );
}

plan tests => $count;

my $ua = LWP::UserAgent->new;
$ua->agent('BBBike.org-Test/1.0');
$ua->env_proxy;

foreach my $obj (@list) {
    my $url = $obj->{'page'};

    my $resp = $ua->get($url);
    ok( $resp->is_success, $url );

    my $mime_type = exists $obj->{mime_type} ? $obj->{mime_type} : "text/html";
    is( $resp->content_type, $mime_type, "page $url is $mime_type" );
    my $content = $resp->decoded_content;
    my $content_length =
      defined $resp->content_length ? $resp->content_length : length($content);

    cmp_ok( $content_length, ">", $obj->{min_size},
            "page $url is greather than: "
          . $content_length . " > "
          . $obj->{min_size} );

    next if !exists $obj->{'match'};
    foreach my $match ( @{ $obj->{'match'} } ) {
        like $content, qr{$match}, qq{Found string '$match'};
    }
}

__END__
