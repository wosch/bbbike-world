#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::Temp qw(tempfile);

use Test::More::UTF8;
use Extract::Test::Archive;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 5;

sub md5_file {
    my $file = shift;
    my $fh = new IO::File $file, "r";
    die "open file $file: $!\n" if !defined $fh;

    my $data = "";
    while (<$fh>) {
        $data .= $_;
    }

    $fh->close;

    my $md5 = md5_hex($data);
    return $md5;
}

my $prefix   = 'world/t/data-osm';
my $pbf_file = "$prefix/Cusco.osm.pbf";

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";
my $osm_md5 = "259f57887b04bf80a919ca2ad4d4d7ac";

is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

system(qq[world/bin/pbf2osm --osmosis $pbf_file > $tempfile]);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

system(qq[world/bin/osm2pbf $tempfile]);
is( $?, 0, "osm2pbf converter" );

my $node_number = `egrep -c '<node id=' $tempfile`;
my $node_number2 =
  `world/bin/pbf2osm --osmosis $tempfile.pbf | egrep -c '<node id='`;

chomp($node_number);
chomp($node_number2);
is( $node_number, $node_number2, "node number checked: $node_number" );

1;
