#!/usr/local/bin/perl
# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org
#
# routing-validate - test routing of a city

use Getopt::Long;
use Data::Dumper;
use IO::File;

use strict;
use warnings;

our $VERSION = 0.1;

binmode \*STDIN,  ":utf8";
binmode \*STDOUT, ":utf8";

my $debug    = 1;            # 0: quiet, 1: normal, 2: verbose
my $data_osm = 'data-osm';
my $number = 3;

sub usage {
   my $message = shift || "";

   print "$message\n" if $message;

    <<EOF;
usage: $0 [--debug={0..2}] [--dir dir ] [ --number=number] cities ...

--debug=0..2    debug option
--dir  dir      default: $data_osm
--number=number default: $number
EOF
}

sub my_sort {
	my $aa = $a;
	my $bb = $b;

	$aa =~ s/\D.*//;
	$bb =~ s/\D.*//;

	$aa <=> $bb;
}

sub _create_links {
    my %args     = @_;
    my $city     = $args{'city'};
    my $data_osm = $args{'data_osm'};
    my $number   = 3;

    my $file = "$data_osm/$city/strassen";
    warn "open $file\n" if $debug >= 2;
    my $fh = new IO::File $file, "r" or die "open $file: $!\n";

    my @data;
    while (<$fh>) {
        push @data, length($_) . " " . $_;
    }

    @data = reverse sort my_sort @data;
    if ( scalar(@data) <= $number ) {
	warn "less than $number streets\n" if $debug >= 1;
        return @data;
    }
    else {
        my @d;
        my $max = 20 * $number;
        $max = scalar(@data) < $max ? scalar(@data) : $max;
        foreach my $i ( 1 .. $number ) {
            push @d, $data[ int( rand($max) ) ];
        }
        return @d;
    }
}

sub create_links {
   my @data = _create_links(@_);
   my @list;

   foreach my $d (@data) {
	$d =~ s/^\d+\d//;
	$d =~ s/.*?\t\w+\s+//;

	my @pos = split " ", $d;
	push @list, [$pos[0], $pos[-1]];
   }

   return @list;
}

######################################################################
# main
#

my @cities = @ARGV;
die usage("missing city") if $#cities < 0;

GetOptions(
    "debug=i" => \$debug,
    "dir=s"   => \$data_osm,
    "number=i"   => \$number,
) or die usage;

my @data;
foreach my $city (@cities) {
    push @data, [ $city, &create_links( 'city' => $city, 'data_osm' => $data_osm, 'number' => $number )];
}


print Dumper(\@data);

1;
