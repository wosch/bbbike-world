#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

use Test::More;
use IO::File;
use File::stat;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

my $prefix = "world/t/data-osm/tmp";

my @files =
  qw(Berlin.coords.data Potsdam.coords.data _boundary.gz _building.gz _education.gz _landuse.gz _leisure.gz _motortraffic.gz _natural.gz _oepnv.gz _power.gz _public_services.gz _shop.gz _sport.gz _tourism.gz ampeln berlin comments_cyclepath comments_danger comments_ferry comments_kfzverkehr comments_misc comments_mount comments_path comments_route comments_scenic comments_tram deutschland faehren flaechen fragezeichen gesperrt gesperrt_car gesperrt_r gesperrt_s gesperrt_u green handicap_l handicap_s hoehe icao inaccessible_strassen kneipen landstrassen landstrassen2 meta.dd meta.yml nolighting opensearch.crossing.10 opensearch.crossing.10.all.gz opensearch.crossing.100 opensearch.crossing.100.all.gz opensearch.street-coordinates opensearch.streetnames orte orte2 orte_city plaetze poi.gz qualitaet_l qualitaet_s radwege radwege_exact rbahn rbahnhof restaurants sbahn sbahnhof sehenswuerdigkeit strassen strassen-orig.gz strassen_bab ubahn ubahnhof wasserstrassen wasserumland wasserumland2 temp_blockings/bbbike-temp-blockings.pl);

my @size_76c = qw(
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

my @size_3k = qw/
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
  _boundary.gz
  /;

my @size_15k = qw/
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
  scalar(@size_3k) +
  scalar(@size_15k) + 4;

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

    foreach my $f (@size_3k) {
        my $file = "$dir/$f";
        my $st   = stat($file);

        cmp_ok( $st ? $st->size : 0,
            ">", 3_000, "check size > 3k bytes $file" );
    }

    foreach my $f (@size_15k) {
        my $file = "$dir/$f";
        my $st   = stat($file);

        cmp_ok( $st ? $st->size : 0,
            ">", 15_000, "check size > 15k bytes $file" );
    }
}

sub convert {
    my @shell = qw[world/t/data-osm/convert.sh];
    system(@shell) == 0 or die "Command '@shell' failed with status: $?\n";
    is( $?, 0, "convert city" );
}

sub checksum {

    # see world/t/data-osm/convert.sh
    my $md5 = md5_file("$prefix/Cusco/checksum");

    # to sync the checksum files, run:
    # cp ./world/t/data-osm/tmp/Cusco/checksum ./world/t/data-osm/Cusco.checksum

    my $md5_checksum_select =
      $^O =~ m{darwin}i
      ? ["db9f5b2cae816cf162acbe0a2a2187e5"]
      : [
        "02c17c375d37d738ee4c89af33b02cb3",    # debian8
        "e18ef0a6931e800890bb520fc143f1bb",    # debian9
        "4ddccb9ff7d1bfbfa0b16c5a49968667",    # ubuntu14
        "b844998a83cf8d70387b4d891491ae24",    # ubuntu14
        "0f8497f414bd8b43c84e167e9ef2534d",    # ubuntu14
        "3904b69991709bc1c866f3ab01336a9e",    # ubuntu16
      ];
    my $md5_checksum = ( grep { $md5 eq $_ } @$md5_checksum_select )[0];

    isnt( $md5_checksum, (), "Known checksum, no data changes" );
    is( $md5, $md5_checksum, "md5 checksum" );

    my @shell =
      ( "diff", "$prefix/../Cusco.checksum", "$prefix/Cusco/checksum" );
    is( system(@shell), 0, "no md5 checksum changes" )
      or diag( system( join " ", @shell, ">&2" ) );

}

&convert;
&check_files;
&checksum;

__END__
