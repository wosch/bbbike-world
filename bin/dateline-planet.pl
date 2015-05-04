#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# create poly files for the date line

use IO::File;

use lib qw(world/bin world/lib ../lib);
use BBBikePoly;

use strict;
use warnings;

my $debug               = 1;
my $sub_planet_dir      = 'tmp/dateline-planet';
my $sub_planet_conf_dir = 'world/etc/dateline-planet';
my $planet_osm          = "../osm/download/planet-latest-nometa.osm.pbf";

my $osmconvert_factor = 1.2;    # full Granularity

$BBBikePoly::area = {

    # left close
    'left-179' => { 'poly' => [ -1, 179, 1, 179.999 ] },

    # left on date line
    'left-180' => { 'poly' => [ -1, 179, 1, 180 ] },

    # right close
    'right-179' => { 'poly' => [ -1, -179.999, 1, -179 ] },

    # right on date line
    'right-180' => { 'poly' => [ -1, -180, 1, -179 ] },

    # left and right on date line
    'left-right-180' => { 'poly' => [ -1, 179, 1, -179 ] },
};

my $poly = new BBBikePoly( 'debug' => $debug );
my @regions = $poly->list_subplanets;

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

my @shell = ("mkdir -p $sub_planet_dir");
foreach my $region (@regions) {
    my $size    = $poly->subplanet_size($region);
    my $size_mb = $poly->file_size_mb( $size * 1000 * $osmconvert_factor );
    warn "region: $region: $size_mb MB\n" if $debug;

    my $obj = $poly->get_job_obj($region);
    my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

    my $file = "$sub_planet_conf_dir/$region.poly";
    &store_data( $file, $data );

    my @sh = (
        "osmconvert-wrapper", "-o", "$sub_planet_dir/$region.osm.pbf",
        "-B=$file", "--drop-author", "--drop-version", "--out-pbf", $planet_osm
    );
    push @shell, join " ", @sh;
}

store_data( "$sub_planet_conf_dir/sub-planet.sh", join "\0", @shell );

__END__
