#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2014 Wolfram Schneider, http://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_FAST} ) {
        print "1..0 # skip BBBIKE_TEST_FAST\n";
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

my @garmin_styles = qw/osm/;
plan tests => 4 + 5 * scalar(@garmin_styles);

my $pbf_file = 'world/t/data-osm/tmp/Cusco-SRTM.osm.pbf';

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco-SRTM.osm.pbf world/t/data-osm/tmp));
    die "symlink failed: $!\n" if $?;
}

my $pbf_md5 = "d05de959d17e6685e17684a480ec8d98";

# min size of garmin zip file
my $min_size = 230_000;

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

######################################################################
is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched" );

my $tempfile = File::Temp->new( SUFFIX => ".osm" );
my $prefix = $pbf_file;
$prefix =~ s/\.pbf$//;
my $st = 0;

# any style
system(qq[world/bin/pbf2osm --garmin $pbf_file osm]);
is( $?, 0, "pbf2osm --garmin converter" );
my $out = "$prefix.garmin-osm.zip";
$st = stat($out) or die "Cannot stat $out\n";

system(qq[unzip -t $out]);
is( $?, 0, "valid zip file" );

cmp_ok( $st->size, '>', $min_size, "$out greather than $min_size" );

# known styles
foreach my $style (@garmin_styles) {
    system(qq[world/bin/pbf2osm --garmin-$style $pbf_file]);
    is( $?, 0, "pbf2osm --garmin-$style converter" );

    $out = "$prefix.garmin-$style.zip";
    system(qq[unzip -tqq $out]);
    is( $?, 0, "valid zip file" );
    $st = stat($out);
    my $size = $st->size;
    cmp_ok( $size, '>', $min_size, "$out: $size > $min_size" );

    system(qq[world/bin/extract-disk-usage.sh $out > $tempfile]);
    is( $?, 0, "extract disk usage check" );

    my $image_size = `cat $tempfile` * 1024;
    cmp_ok( $image_size, '>', $size, "image size: $image_size > $size" );
}

__END__
