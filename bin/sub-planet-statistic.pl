#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org
#
# test script to check which sub-planets can be used
#
# ./world/bin/sub-planet-statistic.pl ../extract/trash/*.json
#
# or sort by region:
#
# find ../extract/trash -mtime -10 -type f -name '*json' | \
#   xargs ./world/bin/sub-planet-statistic.pl | \
#   awk '{ print $2 }' | sort | uniq -c | sort -nr
#

use JSON;
use Getopt::Long;
use Data::Dumper;

use lib qw(world/lib ../lib);
use Extract::Config;
use Extract::Utils;
use Extract::Planet;

use strict;
use warnings;

binmode( \*STDOUT, ":utf8" );
my $debug = 0;
my $help;

sub usage {
    my $message = shift || "";

    print "$message\n" if $message;

    <<EOF;
usage: $0 [--debug={0..2}] *.json ....

--help
--debug=0..2    debug option
EOF
}

#############################################
# main
#
GetOptions(
    "debug=i" => \$debug,
    "help"    => \$help,
) or die usage;
die usage if $help;

my $config = new Extract::Config;

my $planet        = new Extract::Planet( 'debug' => $debug );
my $extract_utils = Extract::Utils->new( 'debug' => $debug );
die "No file given\n" if !@ARGV;

my $planet_osm = $Extract::Planet::config->{'planet_osm'};

foreach my $file (@ARGV) {
    my $obj = $extract_utils->parse_json_file($file);
    next if !exists $obj->{"coords"} or ref $obj->{"coords"} ne 'ARRAY';

    my $sub_planet = $planet->get_smallest_planet_file(
        'obj'        => $obj,
        'planet_osm' => $obj->{"planet_osm"} || $planet_osm
    );

    # no sub_planet, assume full planet
    $sub_planet = $obj->{"planet_osm"} if !$sub_planet;

    printf( "%s\t%s\t%s\n", $file, $sub_planet, $obj->{"city"} );
}

__END__
