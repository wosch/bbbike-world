#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# create poly sub-planet files

use IO::File;

use lib qw(world/lib ../lib);
use BBBikePoly;

use strict;
use warnings;

my $debug               = 1;
my $sub_planet_dir      = '../osm/download/sub-planet';
my $sub_planet_conf_dir = 'world/etc/sub-planet';
my $planet_osm          = "../osm/download/planet-latest-nometa.osm.pbf";

my $osmconvert_factor = 1.2;    # full Granularity

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

my @shell;
foreach my $region (@regions) {
    my $size    = $poly->subplanet_size($region);
    my $size_mb = $poly->file_size_mb( $size * 1000 * $osmconvert_factor );
    warn "region: $region: $size_mb MB\n" if $debug;

    my $obj = $poly->get_job_obj($region);
    my ( $data, $counter ) = $poly->create_poly_data( 'job' => $obj );

    my $file = "$sub_planet_conf_dir/$region.poly";
    &store_data( $file, $data );

    my @sh = (
        "nice",           "-n15",
        "time",           "osmconvert-wrapper",
        "-o",             "$sub_planet_dir/$region.osm.pbf",
        "-B=$file",       "--drop-author",
        "--drop-version", "--out-pbf",
        $planet_osm
    );
    push @shell, join " ", @sh;
}

my $script = "$sub_planet_conf_dir/sub-planet.sh";
warn "Now run ./world/bin/planet-sub\n" if $debug;
store_data( $script, join "\n", @shell );

__END__
