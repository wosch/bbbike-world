#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2015 Wolfram Schneider, http://bbbike.org
#
# test script to check which sub-planets can be used
#
# /this/script ./extract/trash/*.json
#
use JSON;
use Getopt::Long;
use Data::Dumper;

use lib qw(world/lib ../lib);
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

my $planet = new Extract::Planet( 'debug' => $debug );
my $extract_utils = Extract::Utils->new( 'debug' => $debug );
die "No file given\n" if !@ARGV;

foreach my $file (@ARGV) {
    my $obj = $extract_utils->parse_json_file($file);
    next if !exists $obj->{"coords"} or ref $obj->{"coords"} ne 'ARRAY';

    warn Dumper($obj) if $debug >= 2;

    printf(
        "%s\t%s\t%s\n",
        $file,
        $obj->{"city"},
        $planet->get_smallest_planet_file(
            'obj'        => $obj,
            'planet_osm' => $obj->{"planet_osm"}
        )
    );
}

__END__
