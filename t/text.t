#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

BEGIN {
    system( "env", "PATH=/bin:/usr/bin:/usr/local/bin", "which", "osmium" );
    if ($?) {
        print "1..0 # skip no 'osmium' found, skip tests\n";
        exit;
    }
}

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

plan tests => 5;

my $prefix      = 'world/t/data-osm/tmp';
my $pbf_file    = "$prefix/Cusco-text.osm.pbf";
my $osm_file_xz = "$prefix/Cusco-text.osm.text.xz";

if ( !-f $pbf_file ) {
    die "Directory '$prefix' does not exits\n" if !-d $prefix;
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5    = "58a25e3bae9321015f2dae553672cdcf";
my $osmium_md5 = "1db93bc0a8c89c0aad6b6570a47a7cb7";

# min size of garmin zip file
my $min_size = 200_000;

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

is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );

system(qq[world/bin/pbf2osm --text $pbf_file > $tempfile]);
is( $?,                  0,           "pbf2osm --text converter" );
is( md5_file($tempfile), $osmium_md5, "text md5 checksum matched" );

system(
    qq[world/bin/pbf2osm --text-xz $pbf_file && xzcat $osm_file_xz > $tempfile]
);
is( $?,                  0,           "pbf2osm --text-xz converter" );
is( md5_file($tempfile), $osmium_md5, "text xz md5 checksum matched" );

&cleanup;

__END__
