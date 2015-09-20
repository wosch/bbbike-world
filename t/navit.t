#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::stat;

use lib qw(./world/lib ../lib);
use Test::More::UTF8;
use Extract::Test::Archive;

use strict;
use warnings;

my $pbf_file = 'world/t/data-osm/tmp/Cusco.osm.pbf';

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp)) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "6dc9df64ddc42347bbb70bc134b4feda";

# min size of zip file
my $min_size = 200_000;

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

sub convert_format {
    my $lang    = shift;
    my $counter = 5;

    $ENV{'BBBIKE_EXTRACT_LANG'} = $lang;

    # delete empty value
    if ( !$ENV{'BBBIKE_EXTRACT_LANG'} || $ENV{'BBBIKE_EXTRACT_LANG'} eq "" ) {
        delete $ENV{'BBBIKE_EXTRACT_LANG'};
        $lang = "";
    }
    $ENV{BBBIKE_EXTRACT_URL} =
'http://extract.bbbike.org/?sw_lng=-72.33&sw_lat=-13.712&ne_lng=-71.532&ne_lat=-13.217&format=png-google.zip&city=Cusco%2C%20Peru&lang='
      . $lang;
    $ENV{BBBIKE_EXTRACT_COORDS} = "-72.329,-13.711 x -71.531,-13.216";

    my $tempfile = File::Temp->new( SUFFIX => ".osm" );
    my $prefix = $pbf_file;
    $prefix =~ s/\.pbf$//;
    my $st = 0;

    my $out =
      "$prefix.navit"
      . (    $lang
          && $lang ne "en" ? ".$ENV{'BBBIKE_EXTRACT_LANG'}.zip" : ".zip" );
    unlink $out;

    my $test = Extract::Test::Archive->new(
        'lang'        => $lang,
        'file'        => $out,
        'format'      => 'navit',
        'format_name' => 'Navit'
    );

    system(qq[world/bin/pbf2osm --navit $pbf_file Cusco]);
    is( $?, 0, "pbf2osm --navit converter" );
    $st = stat($out) or die "Cannot stat $out\n";

    system(qq[unzip -t $out]);
    is( $?, 0, "valid zip file" );

    my $size = $st->size;
    cmp_ok( $size, '>', $min_size, "$out: $size > $min_size" );

    system(qq[world/bin/extract-disk-usage.sh $out > $tempfile]);
    is( $?, 0, "extract disk usage check" );

    my $image_size = `cat $tempfile` * 1024;
    $image_size *= 1.02
      ;   # navit has good compression, add more to avoid false positive reports

    cmp_ok( $image_size, '>', $size, "image size: $image_size > $size" );

    $counter += $test->validate;
    return $counter;
}

#######################################################
#
is( $pbf_md5, md5_file($pbf_file), "md5 checksum matched" );

my $counter = 0;
my @lang = ( "en", "de" );

if ( !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG} ) {
    push @lang, ( "fr", "es", "ru", "" );
}

foreach my $lang (@lang) {
    $counter += &convert_format($lang);
}

plan tests => 1 + $counter;

__END__
