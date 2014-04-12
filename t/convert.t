#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN { }

use Test::More;
use IO::File;
use File::stat;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

my $prefix = "world/t/data-osm/tmp";

my @files =
  qw(Berlin.coords.data Potsdam.coords.data _boundary.gz _building.gz _education.gz _landuse.gz _leisure.gz _motortraffic.gz _natural.gz _oepnv.gz _power.gz _public_services.gz _shop.gz _sport.gz _tourism.gz ampeln berlin borders comments_cyclepath comments_danger comments_ferry comments_kfzverkehr comments_misc comments_mount comments_path comments_route comments_scenic comments_tram deutschland faehren flaechen fragezeichen gesperrt gesperrt_car gesperrt_r gesperrt_s gesperrt_u green handicap_l handicap_s hoehe icao inaccessible_strassen kneipen landstrassen landstrassen2 meta.dd meta.yml nolighting opensearch.crossing.10 opensearch.crossing.10.all.gz opensearch.crossing.100 opensearch.crossing.100.all.gz opensearch.street-coordinates opensearch.streetnames orte orte2 orte_city plaetze poi.gz qualitaet_l qualitaet_s radwege radwege_exact rbahn rbahnhof restaurants sbahn sbahnhof sehenswuerdigkeit strassen strassen-orig.gz strassen_bab ubahn ubahnhof wasserstrassen wasserumland wasserumland2 temp_blockings/bbbike-temp-blockings.pl);

my @size_76c = qw(
  _boundary.gz
  _building.gz
  _education.gz
  _landuse.gz
  _leisure.gz
  _motortraffic.gz
  _natural.gz
  _oepnv.gz
  _power.gz
  _public_services.gz
  _shop.gz
  _sport.gz
  _tourism.gz
  ampeln
  borders
  flaechen
  fragezeichen
  gesperrt
  handicap_s
  hoehe
  icao
  inaccessible_strassen
  kneipen
  meta.dd
  meta.yml
  opensearch.crossing.10
  opensearch.crossing.10.all.gz
  opensearch.crossing.100
  opensearch.crossing.100.all.gz
  opensearch.street-coordinates
  opensearch.streetnames
  orte
  poi.gz
  qualitaet_s
  radwege_exact
  rbahn
  rbahnhof
  restaurants
  sehenswuerdigkeit
  strassen
  strassen-orig.gz
  strassen_bab
  temp_blockings/bbbike-temp-blockings.pl
  wasserstrassen
);

my @size_10k = qw/
  _boundary.gz
  flaechen
  gesperrt
  handicap_s
  inaccessible_strassen
  opensearch.crossing.10
  opensearch.crossing.10.all.gz
  opensearch.crossing.100
  opensearch.crossing.100.all.gz
  opensearch.street-coordinates
  opensearch.streetnames
  qualitaet_s
  rbahn
  sehenswuerdigkeit
  strassen
  strassen-orig.gz
  strassen_bab
  wasserstrassen
  /;

my @size_50k = qw/
  _boundary.gz
  inaccessible_strassen
  opensearch.crossing.10
  opensearch.crossing.100
  opensearch.street-coordinates
  opensearch.streetnames
  qualitaet_s
  strassen
  strassen-orig.gz
  wasserstrassen
  /;

plan tests => scalar(@files) +
  scalar(@size_76c) +
  scalar(@size_10k) +
  scalar(@size_50k) + 2;

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

sub check_files {
    my $city = shift || 'Cusco';
    my $dir = "$prefix/${city}-data-osm/$city";

    foreach my $f (@files) {
        my $file = "$dir/$f";
        my $st   = stat($file);

        cmp_ok( $st ? $st->size : 0, ">=", 76, "check size $file" );
    }

    foreach my $f (@size_76c) {
        my $file = "$dir/$f";
        my $st   = stat($file);

        cmp_ok( $st ? $st->size : 0, ">=", 76, "check size >= 76 bytes $file" );
    }

    foreach my $f (@size_10k) {
        my $file = "$dir/$f";
        my $st   = stat($file);

        cmp_ok( $st ? $st->size : 0,
            ">", 1024 * 10, "check size > 10k bytes $file" );
    }

    foreach my $f (@size_50k) {
        my $file = "$dir/$f";
        my $st   = stat($file);

        cmp_ok( $st ? $st->size : 0,
            ">", 1024 * 50, "check size > 50k bytes $file" );
    }
}

sub convert {
    my $shell = 'world/t/data-osm/convert.sh';
    system($shell);
    is( $?, 0, "convert city" );
}

sub checksum {
    my $md5 = md5_file("$prefix/Cusco/checksum");
    my $md5_checksum_select =
      $^O =~ m{darwin}i
      ? ["db9f5b2cae816cf162acbe0a2a2187e5"]
      : [
        "8c67a337a4caf77923c8e392a5b3cf0c", # debian7
	"2f83736c3053b38ec82da4c31fdfc3a4", # debian6
      ];
    my $md5_checksum = ( grep { $md5 eq $_ } @$md5_checksum_select )[0];

    is( $md5, $md5_checksum, "md5 checksum" );
}

&convert;
&check_files;
&checksum;

__END__
