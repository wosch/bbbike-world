#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, https://bbbike.org
#
# check pbf2osm results for a *.pbf with zero file size
#

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

my $debug = 0;

# 0: success, 1: non-zero exit status, 99: ignore
my %formats = (

    # osmconvert
    "--osm" => 1,
    "--o5m" => 1,
    "--csv" => 1,

    # osmosis
    "--osmosis" => 0,

    "--navit"          => 99,
    "--shape"          => 99,
    "--osmand"         => 99,
    "--garmin-osm"     => 99,
    "--garmin-cycle"   => 99,
    "--garmin-leisure" => 99,
    "--garmin-bbbike"  => 99,
    "--mapsforge-osm"  => 1
);

# run shape files only if we have more than 1.8GB RAM
if ( -e "/proc/meminfo" ) {
    system(
q[egrep '^MemTotal: ' /proc/meminfo | awk '{ if ($2 > 1.8 * 1000000) { exit 0 } else { exit 1 }}']
    );
    if ($?) {
        warn "1..0 # skip pbf2osm --shape due less than 1.8GB memory\n";
        delete $formats{"--shape"};
    }
}

if ( $ENV{BBBIKE_TEST_FAST} ) {
    delete $formats{"--garmin-cycle"};
    delete $formats{"--garmin-leisure"};
    delete $formats{"--garmin-bbbike"};
}
delete $formats{"--garmin-bbbike"} if !$ENV{BBBIKE_TEST_LONG};

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

is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched: $pbf_file" );

foreach my $format ( sort keys %formats ) {
    if ( $formats{$format} == 99 ) {
        diag("skip format check for: $format");
        ok( 1, "skip $format" );
        next;
    }

    diag(qq[world/bin/pbf2osm $format $pbf_file > $tempfile]) if $debug;

    system(qq[world/bin/pbf2osm $format $pbf_file > $tempfile]);
    is( $? == 0 ? 0 : 1, $formats{$format}, "pbf2osm '$format' failed: $?" );
}

unlink $pbf_file;

1;

__END__
