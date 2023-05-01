#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use IO::File;
use File::stat;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $prefix      = "world/t/data-osm/tmp";
my $lsb_release = `lsb_release -cs`;
chomp($lsb_release);

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
  scalar(@size_15k) + 1 +
  ( $lsb_release eq 'jessieXXX' || $ENV{BBBIKE_TEST_LONG_XXX} ? 1 : 0 );

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

sub check_files {
    my $city = shift || 'Cusco';
    my $dir  = "$prefix/${city}-data-osm/$city";

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
    #my $lsb_release = `lsb_release -cs`;
    #chomp($lsb_release);

    my $md5 = md5_file("$prefix/Cusco/checksum.$lsb_release");

# to sync the checksum files, run:
# cp ./world/t/data-osm/tmp/Cusco/checksum.$(lsb_release -cs) ./world/t/data-osm/Cusco.checksum.$(lsb_release -cs)

    my @shell = (
        "diff",
        "$prefix/../Cusco.checksum.$lsb_release",
        "$prefix/Cusco/checksum.$lsb_release"
    );
    is( system(@shell), 0, "no md5 checksum changes" )
      or diag( system( join " ", @shell, ">&2" ) );

}

&convert;
&check_files;
&checksum if $lsb_release eq 'jessieXXX' || $ENV{BBBIKE_TEST_LONG_XXX};

__END__
