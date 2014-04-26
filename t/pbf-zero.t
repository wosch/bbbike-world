#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org
#
# check pbf2osm results for a *.pbf with zero file size
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

my $debug = 0;

# 0: success, 1: non-zero exit status
my %formats = (

    # osmconvert
    "--osm"   => 1,
    "--o5m"   => 1,
    "--csv"   => 1,
    "--navit" => 1,

    # osmosis
    "--osmosis" => 0,

    "--shape"          => 0,
    "--osmand"         => 0,
    "--garmin-osm"     => 0,
    "--garmin-cycle"   => 0,
    "--garmin-leisure" => 0,
    "--garmin-bbbike"  => 0,
    "--mapsforge-osm"  => 1
);

plan tests => 1 + scalar( keys %formats );

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

my $pbf_file = 'world/t/data-osm/tmp/zero.osm.pbf';
my $pbf_md5  = "d41d8cd98f00b204e9800998ecf8427e";
my $tempfile = File::Temp->new( SUFFIX => ".osm" );

if ( !-f $pbf_file ) {
    system("touch $pbf_file") == 0
      or die "touch $pbf_file failed: $?\n";
}

is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched: $pbf_file" );

foreach my $format ( sort keys %formats ) {
    diag(qq[world/bin/pbf2osm $format $pbf_file > $tempfile]) if $debug;

    system(qq[world/bin/pbf2osm $format $pbf_file > $tempfile]);
    is( $? == 0 ? 0 : 1, $formats{$format}, "pbf2osm $format" );
}

__END__
