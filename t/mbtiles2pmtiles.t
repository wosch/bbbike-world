#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2023 Wolfram Schneider, https://bbbike.org

BEGIN {
    system( "env", "PATH=/bin:/usr/bin:/usr/local/bin", "which", "tilemaker" );
    if ($?) {
        print "1..0 # skip no 'tilemaker' found, skip mbtiles tests\n";
        exit;
    }

    system( "env", "PATH=/bin:/usr/bin:/usr/local/bin", "which", "pmtiles" );
    if ($?) {
        print "1..0 # skip no 'pmtiles' found, skip pmtiles convert tests\n";
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

my @mbtiles_styles = qw/basic/;
push @mbtiles_styles, qw/openmaptiles/
  if !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG};

my $pbf_file;
$pbf_file = 'world/t/data-osm/tmp/Cusco-mbtiles.osm.pbf';

if ( !-f $pbf_file ) {
    system( qw(ln -sf ../Cusco.osm.pbf), $pbf_file ) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "58a25e3bae9321015f2dae553672cdcf";

# min size of garmin zip file
my $min_size = 240_000;

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

    # known styles
    foreach my $style (@mbtiles_styles) {
        my $out = $test->out($style);
        unlink $out;

        diag "mbtiles style=$style, lang=$lang";

        system(qq[world/bin/pbf2osm --mbtiles-$style $pbf_file $city]);
        is( $?, 0, "pbf2osm --mbtiles-$style $pbf_file" );

        system(qq[unzip -tqq $out]);
        is( $?, 0, "valid zip file" );
        $st = stat($out);
        my $size = $st->size;
        my $min_size_style =
          $style =~ /^on(road|trail)/ ? $min_size / 3 : $min_size;
        cmp_ok( $size, '>', $min_size_style, "$out: $size > $min_size" );

        system(qq[world/bin/extract-disk-usage.sh $out > $tempfile]);
        is( $?, 0, "extract disk usage check" );

        my $image_size = `cat $tempfile` * 1024;
        cmp_ok( $image_size, '>', $size, "image size: $image_size > $size" );

        $counter += 5;
        $test->validate( 'style' => $style );

        unlink( $out, "$out.md5", "$out.sha256" );
    }

    return $counter + $test->counter;
}

sub cleanup {
    unlink $pbf_file;
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
    $counter += &convert_format( $lang, 'mbtiles', 'mbtiles' );
}

&cleanup;

plan tests => 1 + $counter;
__END__
