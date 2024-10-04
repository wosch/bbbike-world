#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2023 Wolfram Schneider, https://bbbike.org
#
# create poly files for the date line

use IO::File;
use File::Basename;

use lib qw(world/lib ../lib);
use Extract::Poly;

use strict;
use warnings;

my $debug               = 0;
my $sub_planet_dir      = 'tmp/dateline-planet';
my $sub_planet_conf_dir = 'world/etc/dateline-planet';
my $planet_osm          = "../osm/download/planet-daily.osm.pbf";
my $planet_osm_original = "../osm/download/pbf/planet-latest.osm.pbf";

my $osmconvert_factor = 1.2;    # full Granularity

my $dateline_area = {

    # left close
    'left-179' => { 'poly' => [ 179, -17, 179.999, -16, ] },

    # left on date line
    'left-180' => { 'poly' => [ 179, -17, 180, -16 ] },

    # right close
    'right-179' => { 'poly' => [ -179.999, -17, -179, 17 ] },

    # right on date line
    'right-180' => { 'poly' => [ -180, -17, -179, -16 ] },

    # left and right on date line
    'left-right-180' => { 'poly' => [ 179, -17, -179, -16 ] },

    # a real island
    'fiji' => { 'poly' => [ 175, -20, -170, -10 ] },
};

my $city_area = {
    'san-francisco' => { 'poly' => [ -122.607, 37.595, -122.224, 37.949 ] },
    'berlin'        => { 'poly' => [ 13.321,   52.467, 13.457,   52.564 ] },
    'singapore'     => { 'poly' => [ 103.486,  1.145,  104.075,  1.594 ] },
    'sofia'         => { 'poly' => [ 23.106,   42.589, 23.515,   42.817 ] },
    'malta'         => { 'poly' => [ 14.014,   35.677, 14.745,   36.21 ] },

  #'new-zealand'         => { 'poly' => [ 164.887, -47.559, 178.985, -33.851] },
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
    my $reg        = shift;
    my $planet_osm = shift;

    my @regions = @$reg;

    my @osmconvert_sh = ("mkdir -p $sub_planet_dir");
    my @osmosis_sh    = (
        "osmosis", "-q", "--read-pbf", "file=$planet_osm", "--tee",
        scalar(@regions)
    );
    my @overpass_sh;

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
            "$sub_planet_dir/${prefix}-osmconvert-${region}.osm.pbf",
            "-B=$file",
            "--drop-author",
            "--drop-version",
            "--out-pbf",
            $planet_osm
        );

        my @sh2 = (
            "--bounding-polygon",
            "file=$file",
            "--write-pbf",
            "file=$sub_planet_dir/${prefix}-osmosis-${region}.osm.pbf",
            " omitmetadata=true"
        );

        my $url = $poly->create_overpass_api_url( 'job' => $obj );
        my @sh3 = (
            "curl", "-A", "BBBike.org-Test/1.1", "-g", "-sSf",, qq["$url"], "|",
            "time", "osmconvert", "--out-pbf", "-", ">",
            "$sub_planet_dir/${prefix}-overpass-${region}.osm.pbf"
        );

        push @osmconvert_sh, join " ", @sh;
        push @osmosis_sh,    @sh2;
        push @overpass_sh,   join " ", @sh3;
    }

    my $osmosis_sh = join " ", @osmosis_sh;
    return ( \@osmconvert_sh, $osmosis_sh, \@overpass_sh );
}

sub create_shell_commands {
    my $poly       = shift;
    my $cities     = shift;
    my $planet_osm = shift;

    my $prefix  = basename( $planet_osm, ".osm.pbf" );
    my @regions = $poly->list_subplanets;
    my ( $osmconvert_sh, $osmosis_sh, $overpass_sh ) =
      output( $poly, \@regions, $planet_osm );

    my $file = "$sub_planet_conf_dir/$cities-$prefix-osmconvert.sh";
    store_data( $file, join "\n", @$osmconvert_sh );
    warn
"perl -npe 's/\\n/\\0/g' $file | time nice -15 xargs -0 -n1 -P3 /bin/sh -c\n";

    $file = "$sub_planet_conf_dir/$cities-$prefix-osmosis.sh";
    store_data( $file, join "\n", $osmosis_sh );
    warn
"perl -npe 's/\\n/\\0/g' $file | time nice -15 xargs -0 -n1 -P1 /bin/sh -c\n";

    if ( $planet_osm ne $planet_osm_original ) {
        $file = "$sub_planet_conf_dir/$cities-$prefix-overpass.sh";
        store_data( $file, join "\n", @$overpass_sh );
        warn
"perl -npe 's/\\n/\\0/g' $file | time nice -15 xargs -0 -n1 -P1 /bin/sh -c\n";
    }
}

#####################################################################################
#
#

# date line
$Extract::Poly::area = $dateline_area;
my $poly = new Extract::Poly( 'debug' => $debug );

&create_shell_commands( $poly, 'dateline', $planet_osm );
&create_shell_commands( $poly, 'dateline', $planet_osm_original );

# cities / islands
$Extract::Poly::area = $city_area;
$poly                = new Extract::Poly( 'debug' => $debug );

&create_shell_commands( $poly, 'cities', $planet_osm );
&create_shell_commands( $poly, 'cities', $planet_osm_original );

__END__
