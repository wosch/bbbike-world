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
use File::stat;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 7;

my $prefix       = 'world/t/data-osm/tmp';
my $pbf_file     = "$prefix/Cusco-csv.osm.pbf";
my $osm_file_gz  = "$prefix/Cusco-csv.osm.csv.gz";
my $osm_file_bz2 = "$prefix/Cusco-csv.osm.csv.bz2";
my $osm_file_xz  = "$prefix/Cusco-csv.osm.csv.xz";

if ( !-f $pbf_file ) {
    die "Directory '$prefix' does not exits\n" if !-d $prefix;
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";
my $csv_md5 = "334c1fbe8b35a4060cc340cee039ecbc";

# min size of garmin zip file
my $min_size = 200_000;

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

sub cleanup {
    unlink( $pbf_file, $osm_file_gz, $osm_file_bz2, $osm_file_xz );
}

######################################################################

if ( !-f $pbf_file ) {
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

system(
qq[world/bin/pbf2osm --csv-gzip $pbf_file && gzip -dc $osm_file_gz > $tempfile]
);
is( $?,                  0,        "pbf2osm --csv-gzip converter" );
is( md5_file($tempfile), $csv_md5, "csv gzip md5 checksum matched" );

system(
qq[world/bin/pbf2osm --csv-bzip2 $pbf_file && bzcat $osm_file_bz2 > $tempfile]
);
is( $?,                  0,        "pbf2osm --csv-bzip2 converter" );
is( md5_file($tempfile), $csv_md5, "csv bzip2 md5 checksum matched" );

system(
    qq[world/bin/pbf2osm --csv-xz $pbf_file && xzcat $osm_file_xz > $tempfile]);
is( $?,                  0,        "pbf2osm --csv-xz converter" );
is( md5_file($tempfile), $csv_md5, "csv xz md5 checksum matched" );

&cleanup;

__END__
