#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org
#
# test script to check how long it takes to convert PBF to an other format (e.g. garmin)
#
# ./world/bin/extract-formats-statistic.pl  $(find ../extract/trash -mtime -30 -type f)
#
# or as CSV:
#
# find ../extract/trash -mtime -7 -type f | \
#   xargs ./world/bin/extract-formats-statistic.pl --dump | \
#   egrep  -v '\s0$' | grep garmin-onroad | \
#   awk '{ a+=$2; b+=$3; c+=$4}END { print b/a, "factor",  a/1024/1024/NR, "MB", a/1024/1024/NR/ (c/NR), "MB per sec", c/NR}'
#
#   0.0788477 factor 471.736 MB 0.798359 MB per sec 590.882
#

use FindBin;
use lib "$FindBin::RealBin/../lib";

use JSON;
use Getopt::Long;
use Data::Dumper;

use Extract::Config;
use Extract::Utils;
use Extract::Planet;

use strict;
use warnings;

binmode( \*STDOUT, ":utf8" );
my $debug = 0;

sub usage {
    my $message = shift || "";

    print "$message\n" if $message;

    <<EOF;
usage: $0 [--debug={0..2}] *.json ....

--help
--debug=0..2    debug option
EOF
}

sub dump_data {
    my @data = @_;

    foreach my $o (@data) {
        print join "\t", @$o;
        print "\n";
    }
}

sub statistic {
    my $hash = shift;

    foreach my $format ( sort keys %$hash ) {
        my $counter     = $hash->{$format}->{"counter"};
        my $format_size = $hash->{$format}->{"format_size"}
          // $hash->{$format}->{"image_size_zip"};
        my $pbf_file_size = $hash->{$format}->{"pbf_file_size"};
        my $convert_time  = $hash->{$format}->{"convert_time"};

        printf(
            "format=%s\tpbf=%2.1f MB, image=%2.1f MB, ",
            $format,
            $pbf_file_size / $counter / 1024 / 1024,
            $format_size / $counter / 1024 / 1024
        );
        printf(
            "scale=%2.2f, %d sec, ",
            $format_size / $pbf_file_size,
            $convert_time / $counter
        );

        my $image_factor = $format_size / $convert_time / 1024 / 1024;

        printf(
            "PBF MB/s=%2.2f, Image factor MB/s=%2.2f counter=%d\n",
            $pbf_file_size / $convert_time / 1024 / 1024,
            ( $image_factor != 0 ? 1 / $image_factor : 0 ), $counter
        );

        print Dumper( $hash->{$format} ) if $debug >= 2;
    }
}

#############################################
# main
#
my $dump;
my $help;

GetOptions(
    "debug=i" => \$debug,
    "dump"    => \$dump,
    "help"    => \$help,
) or die usage;
die usage if $help;

my $extract_utils = Extract::Utils->new( 'debug' => $debug );
die "No file given\n" if !@ARGV;

my @data;
my $hash;
foreach my $file (@ARGV) {
    my $obj = $extract_utils->parse_json_file($file);
    next if !exists $obj->{"coords"} or ref $obj->{"coords"} ne 'ARRAY';

    push @data,
      [
        $obj->{"format"}, $obj->{"pbf_file_size"},
        $obj->{"image_size_zip"} // 0, $obj->{"convert_time"}
      ];

    if ( $obj->{"convert_time"} ) {
        my $format = $obj->{"format"};
        $hash->{$format}->{"pbf_file_size"}  += $obj->{"pbf_file_size"};
        $hash->{$format}->{"image_size_zip"} += $obj->{"image_size_zip"} // 0;
        $hash->{$format}->{"convert_time"}   += $obj->{"convert_time"};
        $hash->{$format}->{"counter"}        += 1;
    }
}

if ($dump) {
    dump_data(@data);
}
else {
    statistic($hash);
}

__END__
