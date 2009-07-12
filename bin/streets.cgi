#!/usr/bin/perl

use CGI qw(escape);

# use warnings make the script 20% slower!
#use warnings;
use strict;

$ENV{LANG} = 'C';

my $use_osm_map = 1; # fall back is google maps

my $opensearch_file = 'opensearch.streetnames';
my $opensearch_dir  = '../data-osm';
my $opensearch_dir2  = '../data-opensearch';

my $debug         = 2;
my $match_anyware = 1;

# performance tuning, egrep may be faster than perl regex
my $use_egrep = 1;

sub ascii2unicode {
    my $string = shift;

    warn "yyy: $string\n";

    my ( $ascii, $unicode, $gps ) = split( /\t/, $string );

    if ( !defined $gps) {
	return [$ascii, $unicode];	
    } else {
        warn "ascii2unicode: $unicode\n" if $debug >= 1;
	return [$unicode, $gps];	
    }
}

sub street_match {
    my $file   = shift;
    my $street = shift;
    my $limit  = shift;

    if ( !-e $file ) {
        warn "$!: $file\n";
        return;
    }

    warn "XXX: $street\n";
    if ($use_egrep) {
        open( IN, '-|' ) || exec 'egrep', '-s', '-m', '2000', "$street",
          $file;
    }
    else {
        if ( !open( IN, $file ) ) { warn "$!: $file\n"; return; }
    }

    # to slow
    # binmode(\*IN, ":utf8");

    my @data;
    my @data2;
    my $len = length($street);
    while (<IN>) {

        # match from beginning
        if (/$street/) {
            warn "abc: $_";
            chomp;
            return &ascii2unicode($_);
        }
    }

    close IN;
}

sub streetnames_suggestions_unique {
    my @list = &streetnames_suggestions(@_);

    # return unique list
    my %hash = map { $_ => 1 } @list;
    @list = keys %hash;

    return @list;
}

sub streetnames_suggestions {
    my %args   = @_;
    my $city   = $args{'city'};
    my $street = $args{'street'};
    my $limit  = 16;

    $street =~ s/([\(\)\|\{\}\]\[])/\\$1/g;

    my $file =
      $city eq 'bbbike'
      ? "../data/$opensearch_file"
      : "$opensearch_dir/$city/$opensearch_file";

    if (! -f $file && -f "$opensearch_dir2/$city/$opensearch_file") {
	$file = "$opensearch_dir2/$city/$opensearch_file";
    }

    my $street = &street_match( $file, $street, $limit );

    return if ref $street ne 'ARRAY';


    my ( $name, $gps ) = ($street->[0], $street->[1]);
    my ($x, $y) = split(/,/, $gps);

    return "$y,$x"; # . escape($name);

}

sub strip_list {
    my $limit = shift;
    my @list  = @_;

    $limit = int($limit);

    my @d;
    my $step = int( scalar(@list) / $limit + 0.5 );
    $step = 1 if $step < 1;

    warn "step: $step, list: ", scalar(@list), "\n" if $debug >= 2;
    for ( my $i = 0 ; $i <= $#list ; $i++ ) {
        if ( ( $i % $step ) == 0 ) {
            warn "i: $i, step: $step\n" if $debug >= 2;
            push( @d, $list[$i] );
        }
    }
    return @d;
}

# GET /w/api.php?action=opensearch&search=berlin&namespace=0 HTTP/1.1

my $q = new CGI;

my $action    = 'opensearch';
my $street    = $q->param('search') || $q->param('q') || 'Garibaldi Court';
my $city      = $q->param('city') || 'europe';
my $namespace = $q->param('namespace') || '0';

binmode( \*STDERR, ":utf8" ) if $debug >= 1;

if ($use_osm_map) {
	my ($lat, $lon) = split(/,/,  &streetnames_suggestions('city' => $city, 'street' => $street));
print $q->redirect("http://www.openstreetmap.org/?zoom=16&layers=B000FTF&lat=$lat&lon=$lon");
} else {
print $q->redirect("http://maps.google.ca/maps?q=" . &streetnames_suggestions('city' => $city, 'street' => $street));
}


