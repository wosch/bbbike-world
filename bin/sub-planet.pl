#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# create poly sub-planet files

use IO::File;
use Getopt::Long;

use lib qw(world/lib ../lib);
use Extract::Poly;

use strict;
use warnings;

my $debug       = 1;
my $prefix      = 'sub-planet';
my $planet_osm  = "../osm/download/planet-latest-nometa.osm.pbf";
my $planet_srtm = "../osm/download/srtm/planet-srtm-e40.osm.pbf";

sub usage () {
    <<EOF;
    
usage: $0 [options]

--debug=0..2            debug option
--prefix=prefix         default: $prefix
--planet=planet.osm.pbf default: $planet_osm

EOF
}

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

sub regions {
    my %args = @_;

    my $sub_planet_dir      = $args{'sub_planet_dir'};
    my $sub_planet_conf_dir = $args{'sub_planet_conf_dir'};
    my $planet_osm          = $args{'planet_osm'};

    my $osmconvert_factor = 1.2;    # full Granularity

    my $poly = new Extract::Poly( 'debug' => $debug );
    my @regions = $poly->list_subplanets;

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

    return @shell;
}

#############################################################################
# main
#
my @args = @ARGV;
GetOptions(
    "debug=i"  => \$debug,
    "prefix=s" => \$prefix,
    "planet=s" => \$planet_osm,
) or die usage;

# SRTM planet
if ( $prefix eq 'sub-srtm' && !grep { /--planet=/ } @args ) {
    $planet_osm = $planet_srtm;
    warn "Reset planet_osm to $planet_osm\n" if $debug;
}

my $sub_planet_dir      = "../osm/download/$prefix";
my $sub_planet_conf_dir = "world/etc/$prefix";

my @shell = &regions(
    'planet_osm'          => $planet_osm,
    'sub_planet_dir'      => $sub_planet_dir,
    'sub_planet_conf_dir' => $sub_planet_conf_dir
);

my $script = "$sub_planet_conf_dir/$prefix.sh";
warn "Now run ./world/bin/$prefix\n" if $debug;
store_data( $script, join "\n", @shell );

__END__