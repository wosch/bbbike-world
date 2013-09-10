#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN {
    system( "which", "xmllint" );
    if ($?) {
        print "1..0 # skip no xmllint found, skip tests\n";
        exit;
    }
}

use Getopt::Long;
use Test::More;
use File::stat;

use strict;
use warnings;

plan tests => 9;

######################################################################
system(qq[make -s update-feed]);
is( $?, 0, "update atom feed" );

my $atom_feed = "world/web/feed/bbbike-world.xml";
system(qq[xmllint -format $atom_feed > /dev/null]);
is( $?, 0, "valid xml file" );

my $st       = stat($atom_feed);
my $size     = $st->size;
my $min_size = 20_000;

cmp_ok( $size, '>', $min_size, "$size > $min_size" );
my $data = `cat $atom_feed`;

like( $data, qr|</feed>|, "check xml elements" );
like(
    $data,
    qr|<\?xml version="1.0" encoding="us-ascii"\?>|,
    "check xml elements"
);
like( $data, qr|<title>.+</title>|,     "check xml elements" );
like( $data, qr|<content>.+</content>|, "check xml elements" );
like( $data, qr|<icon>http://|,         "check xml elements" );
like( $data, qr|<entry>|,               "check xml elements" );

__END__
