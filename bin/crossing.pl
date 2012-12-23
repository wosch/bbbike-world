#!/usr/local/bin/perl 
# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org
#
# crossing.pl - extract list of crossings

use Data::Dumper;
use IO::File;

use lib '.';
use lib '..';
use lib '../..';
use lib './lib';
use lib '../../lib';
use Strassen;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = 0.1;

use Getopt::Long;

my $debug       = 0;            # 0: quiet, 1: normal, 2: verbose
my $data_dir    = "data-osm";
my $granularity = 10000;
my $out_file;
my $street_file = "strassen";

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

sub usage () {
    <<EOF;
usage: $0 [--debug={0..2}] [options] cities

--debug=0..2	  		debug option
--data-dir=/path/to/data-osm  	default: $data_dir
--granularity=int		default: $granularity
--out-file=/path/to/output_file
--street_file=strassen		default: $street_file
EOF
}

# fill wgs84 coordinate with trailing "0" if to short
# or cut if to long
sub padding {
    my $x = shift;
    my $gran = shift || $granularity;

    my $len = length($granularity);

    if ( $x =~ /^([\-\+]?\d+)\.?(\d*)$/ ) {
        my ( $int, $rest ) = ( $1, $2 );

        $rest = substr( $rest, 0, $len );
        for ( my $i = length($rest) ; $i < $len ; $i++ ) {
            $rest .= "0";
        }

        return "$int.$rest";
    }
    else {
        return $x;
    }

# foreach my $i (qw/8.12345 8.1234 8.123456 8.1 8 -8 +8 -8.1/) { print "$i: ", padding($i), "\n"; }
}

sub crossing {
    my %args        = @_;
    my $city        = $args{'city'};
    my $data_dir    = $args{'data_dir'};
    my $granularity = $args{'granularity'};
    my $out_file    = $args{'out_file'};
    my $street_file = $args{'street_file'};

    my $file =
      defined $out_file
      ? $out_file
      : "$data_dir/$city/opensearch.crossing." . $granularity;
    my $file_tmp = $file . ".tmp";

    my $strassen = "$data_dir/$city/$street_file";
    warn "granularity: $granularity, strassen: $strassen, out: $file_tmp\n"
      if $debug >= 2;

    my $s             = Strassen->new($strassen);
    my $all_crossings = $s->all_crossings();

    my @data;
    foreach my $c (@$all_crossings) {
        my $x      = $c->[0];
        my $y      = $c->[1];
        my $street = $c->[2];

        push @data, padding($x) . "," . padding($y) . "\t$x,$y\t$street\n";
    }

    my $fh = IO::File->new( $file_tmp, "w" ) or die "open $file_tmp: $!\n";
    print "City: $city, crossings: $#$all_crossings, $file\n" if $debug >= 1;

    binmode $fh, ":utf8";
    print $fh join "", sort @data;

    rename( $file_tmp, $file ) or die "rename $file: $!\n";
}

GetOptions(
    "debug=i"       => \$debug,
    "data-dir=s"    => \$data_dir,
    "granularity=i" => \$granularity,
    "out-file=s"    => \$out_file,
    "street-file=s" => \$street_file,
) or die usage;

my @cities = @ARGV;

die "No cities given\n" . usage if scalar(@cities) <= 0;

foreach my $city (@cities) {
    &crossing(
        'city'        => $city,
        'data_dir'    => $data_dir,
        'granularity' => $granularity,
        'out_file'    => $out_file,
        'street_file' => $street_file,
    );
}

