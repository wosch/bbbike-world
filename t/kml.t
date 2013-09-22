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
use File::Temp qw(tempfile);
use File::stat;

use strict;
use warnings;

plan tests => 4;

######################################################################

my $tempfile = File::Temp->new( SUFFIX => ".kml" );

system(qq[world/bin/bbbike-world-kml world/etc/cities.csv > $tempfile]);
is( $?, 0, "world/bin/bbbike-world-kml" );

system(qq[xmllint -format $tempfile > /dev/null]);
is( $?, 0, "valid kml file" );

my $st       = stat($tempfile);
my $size     = $st->size;
my $min_size = 80_000;

cmp_ok( $size, '>', $min_size, "$size > $min_size" );
my $data = `cat $tempfile`;

like(
    $data,
    qr|http://www.bbbike.org/cgi/area.cgi\?city=[A-Z][a-z]+|,
    "check links in kml"
);

__END__
