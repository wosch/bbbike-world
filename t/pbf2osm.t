#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

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

plan tests => 13;

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

my $prefix       = 'world/t/data-osm/tmp';
my $pbf_file     = "$prefix/Cusco.osm.pbf";
my $osm_file_gz  = "$prefix/Cusco.osm.gz";
my $osm_file_bz2 = "$prefix/Cusco.osm.bz2";
my $osm_file_xz  = "$prefix/Cusco.osm.xz";

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp)) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "6dc9df64ddc42347bbb70bc134b4feda";
my $osm_md5 = "081f6aee335948f325319718d6fd20b7";

is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

system(
qq[world/bin/pbf2osm $pbf_file | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

system(
qq[world/bin/pbf2osm --gzip $pbf_file; gzip -dc $osm_file_gz | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --gzip converter" );
is( md5_file($tempfile), $osm_md5, "osm gzip md5 checksum matched" );

system(
qq[world/bin/pbf2osm --pgzip $pbf_file; gzip -dc $osm_file_gz  | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --pgzip converter" );
is( md5_file($tempfile), $osm_md5, "osm pigz md5 checksum matched" );

system(
qq[world/bin/pbf2osm --bzip2 $pbf_file; bzcat $osm_file_bz2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --bzip2 converter" );
is( md5_file($tempfile), $osm_md5, "osm bzip2 md5 checksum matched" );

system(
qq[world/bin/pbf2osm --pbzip2 $pbf_file; bzcat $osm_file_bz2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --pbzip2 converter" );
is( md5_file($tempfile), $osm_md5, "osm pbzip2 md5 checksum matched" );

system(
qq[world/bin/pbf2osm --xz $pbf_file; xzcat $osm_file_xz | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --xz converter" );
is( md5_file($tempfile), $osm_md5, "osm xz md5 checksum matched" );

__END__
