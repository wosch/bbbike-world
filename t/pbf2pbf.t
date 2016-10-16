#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

BEGIN { }

use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
    "$FindBin::RealBin", );

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

plan tests => 10;

sub md5_file {
    my $file = shift;
    my $fh = new IO::File $file, "r";
    die "open file $file: $!\n" if !defined $fh;

    my $data;
    while (<$fh>) {
        $data .= $_;
    }

    $fh->close;

    my $md5 = md5_hex($data);
    return $md5;
}

my $pbf_file = 'world/t/data-osm/tmp/Cusco.osm.pbf';
if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp)) == 0
      or die "symlink failed: $?\n";
}

my $osmosis_version = `world/bin/bbbike-osmosis-version`;
my $pbf_file2       = 'world/t/data-osm/tmp/Cusco2.osm.pbf';

my $pbf_md5  = "525744cddeef091874eaddc05f10f19b";
my @pbf2_md5 = ("525744cddeef091874eaddc05f10f19b");
my $osm_md5  = "94808e92c1864538916b11890d340b8d";

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched: $pbf_file" );

system(
qq[world/bin/pbf2osm --osmosis $pbf_file | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

system( "cp", $pbf_file, $pbf_file2 );
is( $?,                   0,        "copy" );
is( md5_file($pbf_file2), $pbf_md5, "md5 checksum matched: $pbf_file2" );

system( "world/bin/pbf2pbf", $pbf_file2 );
is( $?, 0, "pbf2pbf $pbf_file2" );

my $md5 = md5_file($pbf_file2);
my $md5_checksum = ( grep { $md5 eq $_ } @pbf2_md5 )[0];

isnt( $md5_checksum, (), "Known checksum, no data changes" );
is( $md5, $md5_checksum, "md5 checksum" );

system(
qq[world/bin/pbf2osm --osmosis $pbf_file2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

__END__
