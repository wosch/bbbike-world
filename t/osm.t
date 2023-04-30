#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, https://bbbike.org

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

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 13;

sub md5_file {
    my $file = shift;
    my $fh   = new IO::File $file, "r";
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
my $pbf_file     = "$prefix/Cusco-osm.osm.pbf";
my $osm_file_gz  = "$prefix/Cusco-osm.osm.gz";
my $osm_file_bz2 = "$prefix/Cusco-osm.osm.bz2";
my $osm_file_xz  = "$prefix/Cusco-osm.osm.xz";

if ( !-f $pbf_file ) {
    die "Directory '$prefix' does not exits\n" if !-d $prefix;
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";
my $osm_md5 = "21e0946ae2e443d31a5f46d0e8bda1b1";

is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

system(
qq[world/bin/pbf2osm $pbf_file | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

system(
qq[world/bin/pbf2osm --gzip $pbf_file && gzip -dc $osm_file_gz | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --gzip converter" );
is( md5_file($tempfile), $osm_md5, "osm gzip md5 checksum matched" );

system(
qq[env MULTI_CPU="NO" world/bin/pbf2osm --gzip $pbf_file && gzip -dc $osm_file_gz  | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --gzip single cpu converter" );
is( md5_file($tempfile), $osm_md5, "osm pigz md5 checksum matched" );

system(
qq[world/bin/pbf2osm --bzip2 $pbf_file && bzcat $osm_file_bz2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --bzip2 converter" );
is( md5_file($tempfile), $osm_md5, "osm bzip2 md5 checksum matched" );

system(
qq[env MULTI_CPU="NO" world/bin/pbf2osm --bzip2 $pbf_file && bzcat $osm_file_bz2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --bzip2 single CPU converter" );
is( md5_file($tempfile), $osm_md5, "osm pbzip2 md5 checksum matched" );

system(
qq[world/bin/pbf2osm --xz $pbf_file && xzcat $osm_file_xz | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm --xz converter" );
is( md5_file($tempfile), $osm_md5, "osm xz md5 checksum matched" );

unlink( $pbf_file, $osm_file_gz, $osm_file_bz2, $osm_file_xz );
__END__
