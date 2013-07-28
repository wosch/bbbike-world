#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN {
    system( "which", "xmllint" );
    if ($?) {
        print "1..0 # skip no xmllint found, skip tests\n";
        exit;
    }
}

use utf8;
use Getopt::Long;
use Test::More;
use File::stat;
use Encode;

use strict;
use warnings;

my @files = qw[index.m.html index.de.html index.en.html index.html];

plan tests => 1 + scalar(@files) * 5 + 1;

######################################################################
system(qq[make -s tagcloud]);
is( $?, 0, "update tagcloud" );

foreach my $file (@files) {
    $file = "world/web/$file";
    my $st       = stat($file);
    my $size     = $st->size;
    my $min_size = 10_000;

    cmp_ok( $size, '>', $min_size, "$file: $size > $min_size" );
    my $data = `cat $file`;
    $data = decode_utf8($data);

    like( $data, qr|</html>|,           "check html elements" );
    like( $data, qr|<title>.+</title>|, "check html elements" );
    like(
        $data,
        qr| href="http://twitter.com/BBBikeWorld" |,
        "check html elements"
    );

    # special checks
    like(
        $data,
qr|<span class="tagcloud\d+"><a class="C_Berlin" href="Berlin/">Berlin</a></span>|,
        "check html elements in $file"
    ) if $file !~ m,/index.m.html$,;

    if ( $file =~ m,/index.html$, ) {
        like(
            $data,
qr|<span class="tagcloud\d+"><a class="C_Sofia" href="Sofia/">София</a></span>|,
            "check utf8 html elements in $file"
        );
    }

    if ( $file =~ m,/index.en.html$, ) {
        like(
            $data,
qr|<span class="tagcloud\d+"><a class="C_Sofia" href="Sofia/">Sofia</a></span>|,
            "check html elements in $file"
        );
    }

}

__END__
