#!/usr/local/bin/perl
# Copyright (c) 2011-2013 Wolfram Schneider, http://bbbike.org
#
# latlng-coord.cgi - plot latlng names on a map as a suggestion service

use lib '.';
use MyCgiSimple;

# use warnings make the script 20% slower!
#use warnings;

use strict;
$ENV{LANG} = 'C';

my $debug = 0;

# how many latlngs to suggestest
my $max_suggestions = 64;

# for the input less than 4 characters
my $max_suggestions_short = 10;

my $opensearch_file = 'opensearch.crossing';
my $opensearch_dir  = '../data-osm';

# wgs84 granularity
my $granularity  = 100;
my $granularity2 = 10;

# word matching for utf8 data
my $force_utf8 = 0;

my $look_command = '/usr/local/bin/look';

# look(1) is faster than egrep, override use_egrep option
my $use_look = 1;

# compute the distance betweent 2 points
# Argument: [x1,y1], [x2, y2]
sub distance {
    CORE::sqrt(
        sqr( $_[0]->[0] - $_[1]->[0] ) + sqr( $_[0]->[1] - $_[1]->[1] ) );
}

sub sqr {
    $_[0] * $_[0];
}

# fill wgs84 coordinate with trailing "0" if to short
# or cut if to long
sub padding {
    my $x           = shift;
    my $granularity = shift;

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

# "13.41029,52.5321" => "13.4152.53"
sub crossing_padding {
    my $crossing    = shift;
    my $granularity = shift;
    my ( $lng, $lat ) = split /,/, $crossing;

    my $c = padding( $lng, $granularity ) . "," . padding( $lat, $granularity );
    warn "crossing: padding: $granularity, $crossing -> $c\n" if $debug >= 1;

    return $c;
}

sub get_crossing {
    my $string = shift;

    my (@data) = split( /\t/, $string );

    # real lat,lng + latlngname
    return $data[1] . "\t" . $data[2];
}

sub latlng_match {
    my $file   = shift;
    my $latlng = shift;
    my $limit  = shift;
    my $binary = shift;

    $binary = 1 if !defined $binary;

    if ( !-e $file ) {
        warn "$!: $file\n";
        return;
    }

    if ($use_look) {
        my $look_opt = '-f';

        # linux only
        $look_opt .= 'b' if $binary && -e '/proc';

        my @command = ( $look_command, $look_opt, "--", $latlng, $file );

        warn join( " ", @command ), "\n" if $debug >= 2;
        open( IN, '-|' ) || exec @command;
    }

    else {
        if ( !open( IN, $file ) ) { warn "$!: $file\n"; return; }
    }

    # to slow
    binmode( \*IN, ":utf8" ) if $force_utf8;

    my @data;
    my $len = length($latlng);

    my $s        = lc($latlng);
    my $s_length = length($s);

    while (<IN>) {
        chomp;
        my $line = lc($_);

        # match from beginning
        if ( $s eq substr( $line, 0, $s_length ) ) {
            warn "latlngname match: $latlng\n" if $debug >= 2;
            push( @data, get_crossing($_) );
        }

        last if scalar(@data) >= $limit * 50;
    }

    close IN;

    warn "data: ", join( " ", @data ), "\n"
      if $debug >= 2;
    return (@data);
}

sub latlngnames_suggestions_unique {
    my %args   = @_;
    my $latlng = $args{'latlng'};

    my @list = &latlngnames_suggestions(@_);

    return &next_crossing(
        'latlng' => $latlng,
        'list'   => \@list,
        'limit'  => 10
    );
}

sub latlngnames_suggestions {
    my %args        = @_;
    my $city        = $args{'city'};
    my $latlng      = $args{'latlng'};
    my $granularity = $args{'granularity'};

    my $limit =
      ( length($latlng) <= 3 ? $max_suggestions_short : $max_suggestions );

    my $latlng_g = crossing_padding( $latlng, $granularity );

    my $file =
      $city eq 'bbbikeXXX'
      ? "../data/$opensearch_file.$granularity"
      : "$opensearch_dir/$city/$opensearch_file.$granularity";

    my (@data) = &latlng_match( $file, $latlng_g, $limit, 0 );
    warn "Len1: ", scalar(@data), " ", join( " ", @data ), "\n" if $debug >= 2;

    return @data;
}

sub escapeQuote {
    my $string = shift;

    $string =~ s/"/\\"/g;

    return $string;
}

sub latlng_coord {
    my $string = shift;

    my ( $coord, $real_coord, $latlng ) = split "\t", $string;

    $coord =~ s/^\S+\s+//;
    return $latlng . "\t" . $coord;
}

sub next_crossing {
    my %args   = @_;
    my $latlng = $args{'latlng'};
    my $list   = $args{'list'};
    my $limit  = $args{'limit'};

    my @list = ref $list eq 'ARRAY' ? @$list : $list;

    my ( $x1, $y1 ) = split /,/, $latlng;
    my @data;
    my %hash;
    foreach my $s (@list) {
        my ( $coord, $name ) = split /\t/, $s;
        my ( $x2,    $y2 )   = split /,/,  $coord;
        next if !$name;

        my $distance = distance( [ $x1, $y1 ], [ $x2, $y2 ] );
        $hash{$s} = $distance;
    }

    @data = sort { $hash{$a} <=> $hash{$b} } keys %hash;
    return scalar(@data) < $limit ? @data : @data[ 0 .. $limit - 1 ];
}

######################################################################
# GET /w/api.php?namespace=1&q=berlin HTTP/1.1
#
# param alias: q: query, search
#              ns: namespace
#

my $q = new MyCgiSimple;

my $action = 'opensearch';
my $latlng =
     $q->param('search')
  || $q->param('query')
  || $q->param('q')
  || '13.41029,52.5321';

if ($force_utf8) {
    require Encode;
    $latlng = Encode::decode( "utf-8" => $latlng );
}

my $city = $q->param('city') || 'Oranienburg';
my $namespace = $q->param('namespace') || $q->param('ns') || '0';

if ( my $d = $q->param('debug') || $q->param('d') ) {
    $debug = $d if defined $d && $d >= 0 && $d <= 3;
}

binmode( \*STDERR, ":utf8" ) if $debug >= 1;

my $expire = $debug >= 2 ? '+1s' : '+1h';
print $q->header(
    -type    => 'text/javascript',
    -charset => 'utf-8',
    -expires => $expire,
);

binmode( \*STDOUT, ":utf8" ) if $force_utf8;

my $latlng_original = $latlng;

my @list = &latlngnames_suggestions_unique(
    'city'        => $city,
    'latlng'      => $latlng,
    'granularity' => $granularity,
);

# try again, with greater tile
if ( scalar(@list) == 0 ) {
    @list = &latlngnames_suggestions_unique(
        'city'        => $city,
        'latlng'      => $latlng,
        'granularity' => $granularity2
    );
}

my @suggestion =
  &next_crossing( 'latlng' => $latlng, 'list' => \@list, 'limit' => 10 );

#@suggestion = map { s/^[^\t]*\t\S+\s+//; $_ } @suggestion;

if ( $debug >= 0 && scalar(@suggestion) <= 0 ) {
    warn "City $city: $latlng, granularity: $granularity2, no coords found!\n";
}
warn "City $city: $latlng", join( " ", @suggestion ), "\n" if $debug >= 2;

######################################################################
# plain text
if ( $namespace eq 'plain' || $namespace == 1 ) {
    print join( "\n", @suggestion ), "\n";
}

# devbridge autocomplete
elsif ( $namespace eq 'dbac' || $namespace == 2 ) {
    print qq/{ query:"/, escapeQuote($latlng), qq/", suggestions:[/;
    print '"', join( '","', map { escapeQuote($_) } @suggestion ), '"'
      if scalar(@suggestion) > 0;
    print "] }";
}

# googe like, with latlng name
elsif ( $namespace eq 'google-latlngnames' || $namespace == 3 ) {
    print qq/["$latlng_original",[/;
    print qq{"}, join( '","', map { escapeQuote( latlng_coord($_) ) } @list ),
      qq{"}
      if scalar(@list) > 0;
    print qq,]],;
}

# googe like
else {
    print qq/["$latlng",[/;
    print qq{"}, join( '","', map { escapeQuote($_) } @suggestion ), qq{"}
      if scalar(@suggestion) > 0;
    print qq,]],;
}

