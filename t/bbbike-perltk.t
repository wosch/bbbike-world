#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2024 Wolfram Schneider, https://bbbike.org

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

my $pbf_file = 'world/t/data-osm/tmp/Cusco-perltk.osm.pbf';

if ( !-f $pbf_file ) {
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";

# min size of zip file
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

sub convert_format {
    my $lang        = shift;
    my $format      = shift;
    my $format_name = shift;

    my $counter  = 5;
    my $tempfile = File::Temp->new( SUFFIX => ".osm" );
    my $st       = 0;

    my $lang_real = $lang;
    if ( $lang !~ /^(en|de)/ ) {
        diag "test for unknown lang='$lang'";
        $lang = 'en';
    }

    my $test = Extract::Test::Archive->new(
        'lang'        => $lang,
        'pbf_file'    => $pbf_file,
        'format'      => $format,
        'format_name' => $format_name
    );
    my $city = $test->init_cusco;
    my $out  = $test->out;
    unlink $out;

    system(qq[world/bin/pbf2osm --bbbike-perltk $pbf_file "$city"]);
    is( $?, 0, qq[pbf2osm --bbbike-perltk $pbf_file "$city"] );
    $st = stat($out) or die "Cannot stat $out\n";

    system(qq[unzip -t $out]);
    is( $?, 0, "valid zip file" );

    my $size = $st->size;
    cmp_ok( $size, '>', $min_size, "$out: $size > $min_size" );

    system(qq[world/bin/extract-disk-usage.sh $out > $tempfile]);
    is( $?, 0, "extract disk usage check" );

    my $image_size = `cat $tempfile` * 1024;
    $image_size *= 1.02;

    cmp_ok( $image_size, '>', $size, "image size: $image_size > $size" );

    $counter += $test->validate;
    unlink( $out, "$out.md5" );

    return $counter;
}

sub cleanup {
    unlink $pbf_file;
}

#######################################################
#
is( md5_file($pbf_file), $pbf_md5, "md5 checksum matched" );

my $counter = 0;
my @lang    = ( "en", "de" );

if ( !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG} ) {
    push @lang, ( "fr", "" );
}

foreach my $lang (@lang) {
    $counter += &convert_format( $lang, 'bbbike-perltk', 'bbbike' );
}

&cleanup;
plan tests => 1 + $counter;

__END__
