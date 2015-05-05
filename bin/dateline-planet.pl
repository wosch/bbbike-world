#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# create poly files for the date line

use IO::File;
use File::Basename;

use lib qw(world/bin world/lib ../lib);
use BBBikePoly;

use strict;
use warnings;

my $debug               = 0;
my $sub_planet_dir      = 'tmp/dateline-planet';
my $sub_planet_conf_dir = 'world/etc/dateline-planet';
my $planet_osm          = "../osm/download/planet-latest-nometa.osm.pbf";
my $planet_osm_original = "../osm/download/pbf/planet-latest.osm.pbf";

my $osmconvert_factor = 1.2;    # full Granularity

my $dateline_area = {

    # left close
    'left-179' => { 'poly' => [ -17, 179, 17, 179.999 ] },

    # left on date line
    'left-180' => { 'poly' => [ -17, 179, 17, 180 ] },

    # right close
    'right-179' => { 'poly' => [ -17, -179.999, 17, -179 ] },

    # right on date line
    'right-180' => { 'poly' => [ -17, -180, 17, -179 ] },

    # left and right on date line
    'left-right-180' => { 'poly' => [ -17, 179, 17, -179 ] },

    # a real island
    'fiji' => { 'poly' => [ -20, 175, -10, -170 ] },
};

my $city_area = {
    'san-francisco' => { 'poly' => [ -122.607, 37.595, -122.224, 37.949 ] },
    'berlin'        => { 'poly' => [ 13.321,   52.467, 13.457,   52.564 ] },
    'singapore'     => { 'poly' => [ 103.486,  1.145,  104.075,  1.594 ] },
    'sofia'         => { 'poly' => [ 23.106,   42.589, 23.515,   42.817 ] },
    'malta'         => { 'poly' => [ 14.014,   35.677, 14.745,   36.21 ] },
};

sub store_data {
    my $file_real = shift;
    my $data      = shift;

    my $file = "$file_real.tmp";

    warn "open > $file\n"      if $debug >= 2;
    warn "poly data:\n$data\n" if $debug >= 3;

    my $fh = new IO::File $file, "w" or die "open $file: $!\n";
    binmode $fh, ":utf8";

    print $fh $data;
    $fh->close;

    warn "Rename $file $file_real\n" if $debug >= 2;
    rename( $file, $file_real ) or die "Rename $file -> $file_real: $!\n";
}

sub output {
    my $poly       = shift;
    my $regions    = shift;
    my $planet_osm = shift;

    my @regions = @$regions;

    my @osmconvert_sh = ("mkdir -p $sub_planet_dir");
    my @osmosis_sh    = (
        "osmosis", "-q", "--read-pbf", "file=$planet_osm", "--tee",
        scalar(@regions)
    );

    my $prefix = basename( $planet_osm, ".osm.pbf" );

    foreach my $region (@regions) {
        my $size    = $poly->subplanet_size($region);
        my $size_mb = $poly->file_size_mb( $size * 1000 * $osmconvert_factor );
        warn "region: $region: $size_mb MB\n" if $debug;

        my $obj = $poly->get_job_obj($region);
        my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

        my $file = "$sub_planet_conf_dir/$region.poly";
        &store_data( $file, $data );

        my @sh = (
            "osmconvert-wrapper",
            "-o",
            "$sub_planet_dir/$prefix-osmconvert-$region.osm.pbf",
            "-B=$file",
            "--drop-author",
            "--drop-version",
            "--out-pbf",
            $planet_osm
        );

        my @sh2 = (
            "--bounding-polygon", "file=$file", "--write-pbf",
            "file=$sub_planet_dir/$prefix-osmosis-region.osm.pbf",
            " omitmetadata=true"
        );

        push @osmconvert_sh, join " ", @sh;
        push @osmosis_sh, @sh2;
    }

    return ( \@osmconvert_sh, join " ", @osmosis_sh );
}

sub create_shell_commands {
    my $poly       = shift;
    my $cities     = shift;
    my $planet_osm = shift;

    my $prefix = basename( $planet_osm, ".osm.pbf" );
    my @regions = $poly->list_subplanets;
    my ( $osmconvert_sh, $osmosis_sh ) =
      output( $poly, \@regions, $planet_osm );

    my $file = "$sub_planet_conf_dir/$cities-$prefix-osmconvert.sh";
    store_data( $file, join "\0", @$osmconvert_sh );
    warn "nice -15 xargs -0 -n1 -P3 /bin/sh -c < $file\n";

    $file = "$sub_planet_conf_dir/$cities-$prefix-osmosis.sh";
    store_data( $file, join "\0", $osmosis_sh );
    warn "nice -15 xargs -0 -n1 -P1 /bin/sh -c < $file\n";

}

#####################################################################################
#
#

# date line
$BBBikePoly::area = $dateline_area;
my $poly = new BBBikePoly( 'debug' => $debug );

&create_shell_commands( $poly, 'dateline', $planet_osm );
&create_shell_commands( $poly, 'dateline', $planet_osm_original );

# cities / islands
$BBBikePoly::area = $city_area;
$poly = new BBBikePoly( 'debug' => $debug );

&create_shell_commands( $poly, 'cities', $planet_osm );
&create_shell_commands( $poly, 'cities', $planet_osm_original );

__END__
