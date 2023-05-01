#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org
#
# test osmosis, legacy

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 9;

sub md5_file {
    my $file = shift;
    my $fh   = new IO::File $file, "r";
    die "open file $file: $!\n" if !defined $fh;

    my $data;
    while (<$fh>) {
        $data .= $_;
    }

    $fh->close;

    my $md5 = md5_hex($data);
    return $md5;
}

my $pbf_file = 'world/t/data-osm/tmp/Cusco-pbf.osm.pbf';
if ( !-f $pbf_file ) {
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $osmosis_version = `world/bin/bbbike-osmosis-version`;
my $pbf_file2       = 'world/t/data-osm/tmp/Cusco-pbf2.osm.pbf';

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";
my $osm_md5 = "b2280a05e4382c3033b6c22c6680085b";

my $pbf2_md5 = "728a53423c671fe25c5dfb6eb31014d9";
my $osm2_md5 = "9341e438f97da1a341dc9fea938a3acc";

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

sub cleanup {
    unlink( $pbf_file, $pbf_file2 );
}

###############################################################################
# test pbf2osm
#
is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched: $pbf_file" );

system(
qq[world/bin/pbf2osm --osmosis $pbf_file | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

###############################################################################
# test pbf2pbf
#
is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched: $pbf_file" );

system( "cp", "-f", $pbf_file, $pbf_file2 );
is( $?,                   0,        "copy" );
is( md5_file($pbf_file2), $pbf_md5, "md5 checksum matched: $pbf_file2" );

system( "world/bin/pbf2pbf", $pbf_file2 );
is( $?, 0, "pbf2pbf $pbf_file2" );

# maybe changed due a newer java version or pbf lib
#is( md5_file($pbf_file2), $pbf2_md5, "md5 checksum" );

system(
qq[world/bin/pbf2osm --osmosis $pbf_file2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,         "pbf2osm converter" );
is( md5_file($tempfile), $osm2_md5, "osm md5 checksum matched" );

&cleanup;
__END__
