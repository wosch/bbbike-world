#!/usr/local/bin/perl
# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org
#
# routing-validate - test routing of a city

use Getopt::Long;
use Data::Dumper;
use IO::File;

use strict;
use warnings;

our $VERSION = 0.1;

binmode \*STDIN,  ":bytes";
binmode \*STDOUT, ":bytes";

my $debug    = 1;                             # 0: quiet, 1: normal, 2: verbose
my $data_osm = 'data-osm';
my $number   = 3;
my $homepage = 'http://dev4.bbbike.org/en';
my $ignore_errors = 0;

my $exit = 0;

sub usage {
    my $message = shift || "";

    print "$message\n" if $message;

    <<EOF;
usage: $0 [--debug={0..2}] [--dir dir ] [ --number=number] cities ...

--help
--debug=0..2    debug option
--dir  dir      default: $data_osm
--number=number default: $number
--homepage=homepage default: $homepage
--ignore-errors	default: $ignore_errors
EOF
}

sub my_sort {
    my $aa = $a;
    my $bb = $b;

    $aa =~ s/\D.*//;
    $bb =~ s/\D.*//;

    $aa <=> $bb;
}

# find inaccessible points
sub inaccessible_strassen {
    my $file = shift;

    warn "open $file\n" if $debug >= 2;
    my $fh = new IO::File $file, "r" or die "open $file: $!\n";
    binmode $fh, ":bytes";

    my %hash;

    while (<$fh>) {
        next if /^\s*#/;
        s/^\S*\s\S+\s+//;
        my @data = split " ", $_;
        map { $hash{$_} = 1 } @data;
    }

    return \%hash;
}

sub _create_links {
    my %args     = @_;
    my $city     = $args{'city'};
    my $data_osm = $args{'data_osm'};
    my $number   = $args{'number'} || 3;

    my $file = "$data_osm/$city/strassen";
    warn "open $file\n" if $debug >= 2;
    my $fh = new IO::File $file, "r" or die "open $file: $!\n";
    binmode $fh, ":bytes";

    my @data;
    my $length;
    while (<$fh>) {
        $length = length($_);
        next if $length < 130;    # optimize

        push @data, "$length $_";
    }

    @data = reverse sort my_sort @data;

    # very few data
    if ( scalar(@data) <= $number ) {
        warn "less than $number streets\n" if $debug >= 1;
        return @data;
    }

    # find long streets, and extract 3 with a random generator
    else {
        my @d;
        my $max     = 50 * $number;
        my $padding = 3;              # get more data, for inaccessable points

        $max = scalar(@data) < $max ? scalar(@data) : $max;

        my %hash;
        foreach my $i ( 1 .. $number * $padding ) {

            # uniqe rand
            my $rand;
            foreach my $j ( 1 .. $number ) {
                $rand = int( rand($max) );
                if ( !exists $hash{$rand} ) {
                    $hash{$rand} = 1;
                    last;
                }
            }

            if ( !defined $rand ) {
                warn "something went wrong with rand check\n";
                next;
            }

            push @d, $data[$rand];
        }

        return @d;
    }
}

sub create_links {
    my %args     = @_;
    my $city     = $args{'city'};
    my $data_osm = $args{'data_osm'};
    my $number   = $args{'number'} || 3;

    my @data = _create_links(@_);
    my @list;

    my $file = "$data_osm/$city/inaccessible_strassen";
    my $hash = inaccessible_strassen($file);

    my $counter = 0;
    foreach my $d (@data) {
        $d =~ s/^\d+\d//;
        $d =~ s/.*?\t\S+\s+//;

        my @pos = split " ", $d;
        if ( !grep { $hash->{$_} } @pos ) {
            push @list, [ $pos[0], $pos[-1] ];
        }
        else {
            warn "Ignore inaccessible street $city\n" if $debug >= 2;
        }

        last if scalar(@list) >= $number;
    }

    if ( scalar(@list) < $number ) {
        warn "Number @{[ scalar(@list) ]} < $number for $city\n" if $debug >= 1;
        $exit++;
    }

    return @list;
}

######################################################################
# main
#

my $help;
GetOptions(
    "debug=i"         => \$debug,
    "dir=s"           => \$data_osm,
    "number=i"        => \$number,
    "homepage=s"      => \$homepage,
    "ignore-errors=i" => \$ignore_errors,
    "help"            => \$help,
) or die usage;
die usage if $help;

my @cities = @ARGV;
die usage("missing city") if $#cities < 0;

my @data;
foreach my $city (@cities) {
    push @data,
      [
        $city,
        &create_links(
            'city'     => $city,
            'data_osm' => $data_osm,
            'number'   => $number
        )
      ];
}

# trailing slash
$homepage =~ s,/+$,,;

foreach my $query (@data) {
    my @query = @$query;
    my $city  = shift @query;
    foreach my $c (@query) {
        my $url =
          qq{$homepage/$city/?renice=10&start=} . $c->[0] . "&ziel=" . $c->[1];
        print
qq{curl -sSf "$url" | egrep -q '"route_length"' || echo "fail $url"\0};
    }
}

exit( ( $exit == 0 || $ignore_errors ) ? 0 : 1 );

1;
