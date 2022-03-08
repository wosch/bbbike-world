#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_NO_NETWORK} ) {
        print "1..0 # skip due no network\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use BBBike::Test;

use strict;
use warnings;

my $test = BBBike::Test->new();

my @list = (
    {
        'page'     => 'https://www.bbike.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'https://bbike.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    #{
    #    # no HTTPS yet
    #    'page'     => 'http://mc.bbike.org/mc/',
    #    'min_size' => 300,
    #    'match'    => [ "</html>", ">Map Compare<" ]
    #},

    {
        'page'     => 'https://www.cyclerouteplanner.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'https://cyclerouteplanner.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    {
        'page'     => 'https://www.cyclerouteplanner.com',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'https://cyclerouteplanner.com',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    #{
    #    'page'     => 'https://www.cycleroute.net',
    #    'min_size' => 10_000,
    #    'match'    => ["</html>"]
    #},
    {
        'page'     => 'https://cycleroute.net',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },

    {
        # no HTTPS yet
        'page'     => 'http://extract.bbike.org',
        'min_size' => 10_000,
        'match'    => ["</html>"]
    },
    {
        'page'     => 'https://debian.bbbike.org',
        'min_size' => 200,
        'match'    => ["</html>"]
    },
);

my $count = 3 * scalar(@list);
foreach my $obj (@list) {
    $count += scalar( @{ $obj->{'match'} } );
}

plan tests => $count;

my $ua = $test->{'ua'};

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
