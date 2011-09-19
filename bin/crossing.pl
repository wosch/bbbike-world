#!/usr/local/bin/perl 
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
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

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

sub usage () {
    <<EOF;
usage: $0 [--debug={0..2}] [options] cities

--debug=0..2	  debug option
--data-dir=/path/to/data-osm  default: $data_dir
--granularity=int	default: $granularity
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
    my %args     = @_;
    my $city     = $args{'city'};
    my $data_dir = $args{'data_dir'};

    my $s             = Strassen->new("$data_dir/$city/strassen");
    my $all_crossings = $s->all_crossings();

    my @data;
    foreach my $c (@$all_crossings) {
        push @data,
          padding( $c->[0] ) . "," . padding( $c->[1] ) . "\t" . $c->[2] . "\n";
    }

    my $file     = "$data_dir/$city/opensearch.crossing";
    my $file_tmp = $file . ".tmp";
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
) or die usage;

my @cities = @ARGV;

die "No cities given\n" . usage if scalar(@cities) <= 0;

foreach my $city (@cities) {
    &crossing( 'city' => $city, 'data_dir' => $data_dir );
}

