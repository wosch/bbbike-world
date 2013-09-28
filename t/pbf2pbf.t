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

plan tests => 9;

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
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp));
    die "symlink failed: $!\n" if $?;
}

my $pbf_file2 = 'world/t/data-osm/tmp/Cusco2.osm.pbf';
my $pbf_md5   = "6dc9df64ddc42347bbb70bc134b4feda";
my $pbf2_md5  = "1c011b6910f5ef7a8cefd76005921680";
my $osm_md5   = "d222cfe84480b8f0ac0081eaf6e2c2ce";
my $tempfile  = File::Temp->new( SUFFIX => ".osm" );

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
is( md5_file($pbf_file2), $pbf2_md5,
    "md5 checksum matched after running pbf2pbf: $pbf_file2" );

system(
qq[world/bin/pbf2osm --osmosis $pbf_file2 | perl -npe 's/timestamp=".*?"/timestamp="0"/' > $tempfile]
);
is( $?,                  0,        "pbf2osm converter" );
is( md5_file($tempfile), $osm_md5, "osm md5 checksum matched" );

__END__
