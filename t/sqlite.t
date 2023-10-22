#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    system(
        "env",   "PATH=/bin:/usr/bin:/usr/local/bin",
        "which", "osmium_toogr2"
    );
    if ($?) {
        print "1..0 # skip no 'osmium_toogr2' found, skip tests\n";
        exit;
    }
}

use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
    "$FindBin::RealBin", );

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use IO::File;
use File::Temp qw(tempfile);
use Digest::MD5 qw(md5_hex);
use File::stat;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 7;

my $prefix      = 'world/t/data-osm/tmp';
my $pbf_file    = "$prefix/Cusco-sqlite.osm.pbf";
my $osm_file_xz = "$prefix/Cusco-sqlite.osm.sqlite.xz";
my $osm_file    = "$prefix/Cusco-sqlite.osm.sqlite";

if ( !-f $pbf_file ) {
    die "Directory '$prefix' does not exits\n" if !-d $prefix;
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";

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

sub cleanup {
    unlink( $pbf_file, $osm_file_xz );
}

######################################################################

if ( !-f $pbf_file ) {
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

system(qq[world/bin/pbf2osm --sqlite $pbf_file]);
is( $?, 0, "world/bin/pbf2osm --sqlite $pbf_file" );
cmp_ok( -s $osm_file, ">=", 2_000_000, "sqlite output size large enough" );
cmp_ok( -s $osm_file, "<=", 3_000_000, "sqlite output size small enough" );

system(qq[world/bin/pbf2osm --sqlite-xz $pbf_file]);
is( $?, 0, "world/bin/pbf2osm --sqlite-xz $pbf_file" );
cmp_ok( -s $osm_file_xz, ">=", 700_000, "sqlite output size large enough" );
cmp_ok( -s $osm_file_xz, "<=", 990_000, "sqlite output size small enough" );

&cleanup;

__END__
