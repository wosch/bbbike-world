#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org

BEGIN {
    my $display = $ENV{BBBIKE_MAPERITIVE_DISPLAY} || $ENV{DISPLAY} || ":200";
    my $display_number = $display;
    $display_number =~ s,^:,,;

    my $lockfile = "/tmp/.X${display_number}-lock";

    if ( !-e $lockfile ) {
        print "1..0 # skip, DISPLAY=$display xvfb not running?\n";
        exit;
    }

    $ENV{DISPLAY} = $display;
}

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::stat;
use File::Basename;

use strict;
use warnings;

my $type = basename( $0, ".t" );    #"svg";

my @svg_styles = qw/google/;
push @svg_styles, qw/osm/ if !$ENV{BBBIKE_TEST_FAST} || $ENV{BBBIKE_TEST_LONG};
push @svg_styles, qw/hiking urbanight wireframe/ if $ENV{BBBIKE_TEST_LONG};

plan tests => 1 + ( 5 * scalar(@svg_styles) );

my $pbf_file = 'world/t/data-osm/tmp/Cusco.osm.pbf';

if ( !-f $pbf_file ) {
    system(qw(ln -sf ../Cusco.osm.pbf world/t/data-osm/tmp)) == 0
      or die "symlink failed: $?\n";
}

my $pbf_md5 = "6dc9df64ddc42347bbb70bc134b4feda";

# min size of garmin zip file
my $min_size = 100_000;

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
my $st      = 0;
my $timeout = 30;
my $out     = "";

# known styles
foreach my $style (@svg_styles) {
    $out = "$prefix.$type-$style.zip";
    unlink($out);

    system(
qq[world/bin/bomb --timeout=$timeout --screenshot-file=$pbf_file.png -- world/bin/pbf2osm --$type-$style $pbf_file]
    );
    is( $?, 0, "pbf2osm --$type-$style converter" );

    system(qq[unzip -tqq $out]);
    is( $?, 0, "valid zip file" );
    $st = stat($out) or warn "stat $out: $!\n";

    my $size = $st ? $st->size : -1;
    cmp_ok( $size, '>', $min_size, "$out: $size > $min_size" );

    system(qq[world/bin/extract-disk-usage.sh $out > $tempfile]);
    is( $?, 0, "extract disk usage check" );

    my $image_size = `cat $tempfile` * 1024;
    cmp_ok( $image_size, '>', $size, "image size: $image_size > $size" );
}

__END__
