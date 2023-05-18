#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2023 Wolfram Schneider, https://bbbike.org

BEGIN {
    if ( $ENV{BBBIKE_TEST_MAPSFORGE_DISABLED} || $ENV{BBBIKE_TEST_DOCKER} ) {
        print "1..0 # skip, mapsforge disabled or running on docker\n";
        exit;
    }
}

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::stat;

use Test::More::UTF8;
use Extract::Test::Archive;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $pbf_file = 'world/t/data-osm/tmp/Cusco-mapsforge.osm.pbf';

if ( !-f $pbf_file ) {
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";

# min size of zip file
my $min_size = 180_000;

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

sub cleanup {
    unlink $pbf_file;
}

######################################################################
sub convert_format {
    my $lang        = shift;
    my $format      = shift;
    my $format_name = shift;

    my $timeout  = 30;
    my $counter  = 0;
    my $tempfile = File::Temp->new( SUFFIX => ".osm" );
    my $st       = 0;

    my $test = Extract::Test::Archive->new(
        'lang'        => $lang,
        'pbf_file'    => $pbf_file,
        'format'      => $format,
        'format_name' => $format_name
    );
    my $city = $test->init_cusco;

    my $style = "osm";

    my $out = $test->out($style);
    unlink $out;

    my $command = qq[world/bin/pbf2osm --mapsforge-$style $pbf_file $city];
    system($command);
    is( $?, 0, $command );
    $st = stat($out) or die "Cannot stat $out\n";

    system(qq[unzip -t $out]);
    is( $?, 0, "valid zip file" );

    my $size = $st->size;
    cmp_ok( $size, '>', $min_size, "$out: $size > $min_size" );

    $counter += 2;
    $test->validate;

    unlink( $out, "$out.md5" );
    return $counter + $test->counter;
}
#######################################################
#
is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

my $counter = 0;
my @lang = ( "en", "de" );

if ( !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG} ) {
    push @lang, ( "fr", "es", "ru", "" );
}

foreach my $lang (@lang) {
    $counter += &convert_format( $lang, 'mapsforge', 'Mapsforge' );
}

&cleanup;
plan tests => 1 + $counter;

__END__
