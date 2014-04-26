#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org
#
# check command output of: pbf2osm --csv
#

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

plan tests => 9;

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
my $csv_file_gz  = "$prefix/Cusco.osm.csv.gz";
my $csv_file_bz2 = "$prefix/Cusco.osm.csv.bz2";
my $csv_file_xz  = "$prefix/Cusco.osm.csv.xz";

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf t/data-osm/tmp)) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "6dc9df64ddc42347bbb70bc134b4feda";
my $csv_md5 = "24dff23d30cf931540d585238314c7c1";

is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".csv" );

system(qq[world/bin/pbf2osm --csv $pbf_file > $tempfile]);
is( $?,                  0,        "pbf2osm --csv converter" );
is( md5_file($tempfile), $csv_md5, "csv md5 checksum matched" );

system(
qq[world/bin/pbf2osm --csv-gzip $pbf_file; gzip -dc $csv_file_gz > $tempfile]
);
is( $?,                  0,        "pbf2osm --csv-gzip converter" );
is( md5_file($tempfile), $csv_md5, "csv gzip md5 checksum matched" );

system(
    qq[world/bin/pbf2osm --csv-bzip2 $pbf_file; bzcat $csv_file_bz2 > $tempfile]
);
is( $?,                  0,        "pbf2osm --csv-bzip2 converter" );
is( md5_file($tempfile), $csv_md5, "csv bzip2 md5 checksum matched" );

system(
    qq[world/bin/pbf2osm --csv-xz $pbf_file; xzcat $csv_file_xz > $tempfile]);
is( $?,                  0,        "pbf2osm --csv-xz converter" );
is( md5_file($tempfile), $csv_md5, "csv xz md5 checksum matched" );

__END__
