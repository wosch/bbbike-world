#!/usr/local/bin/perl -T
# Copyright (c) 2009-2014 Wolfram Schneider, https://bbbike.org
#
# street-coord.cgi - plot street names on a map as a suggestion service
#
# Example:
#
# curl 'https://www.bbbike.org/cgi/street-coord.cgi?namespace=3;city=Duesseldorf&query=Kaiser-Friedrich-R'
#
# ["Kaiser-Friedrich-R",
#    ["Kaiser-Friedrich-Ring	6.76311,51.23167 6.76293,51.23171 6.76267,51.23171 6.76258,51.23171 6.76249,51.23173 6.76243,51.23175 6.76238,51.23179 6.76233,51.23185 6.76231,51.23191 6.76231,51.23225 6.7623,51.2325 6.76232,51.23274 6.76242,51.2329 6.76233,51.23299 6.76229,51.23308 6.76212,51.23374 6.7618,51.23451 6.76142,51.23512 6.7612,51.23544 6.76098,51.23573 6.76072,51.23606 6.76059,51.23624 6.76006,51.23684 6.7595,51.23736 6.75899,51.23777 6.75832,51.23825 6.75819,51.23834 6.75752,51.23881 6.75714,51.23908 6.75686,51.23926 6.75663,51.23942 6.75637,51.23959 6.75441,51.24091 6.75317,51.24178 6.75257,51.24224 6.7525,51.24228 6.75229,51.24244 6.75221,51.24249 6.75159,51.24293", "Kaiser-Friedrich-Ring (B 7)	6.75159,51.24293 6.75155,51.24295 6.7515,51.24296 6.75146,51.24298 6.75141,51.24298 6.75137,51.24299 6.75131,51.24298 6.75125,51.24296 6.75119,51.24294 6.75113,51.24292 6.7508,51.24274 6.75053,51.2426 6.74983,51.24223 6.74964,51.24213 6.74955,51.24209 6.74944,51.24203 6.74926,51.24195 6.74903,51.24185 6.74889,51.2418"]
# ]

use lib '.';
use MyCgiSimple;

# use warnings make the script 20% slower!
#use warnings;

use strict;

$ENV{LANG} = 'C';
$ENV{PATH} = "/bin:/usr/bin";

# how many streets to suggestest
my $max_suggestions = 64;

# for the input less than 4 characters
my $max_suggestions_short = 10;

my $opensearch_file = 'opensearch.street-coordinates';
my $opensearch_dir  = '../data-osm';

my $debug = 0;

# word matching for utf8 data
my $force_utf8 = 0;

my $look_command = '/usr/local/bin/look';

# look(1) is faster than egrep, override use_egrep option
my $use_look = 1;

sub get_coords {
    my $string = shift;

    return $string;
    my (@data) = split( /\t/, $string );

    return $data[1];
}

sub street_match {
    my $file   = shift;
    my $street = shift;
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

        my @command = ( $look_command, $look_opt, "--", $street, $file );

        warn join( " ", @command ), "\n" if $debug >= 2;
        open( IN, '-|' ) || exec @command;
    }

    else {
        if ( !open( IN, $file ) ) { warn "$!: $file\n"; return; }
    }

    # to slow
    binmode( \*IN, ":utf8" ) if $force_utf8;

    my @data;
    my @data2;
    my $len = length($street);

    my $s        = lc($street);
    my $s_length = length($s);

    while (<IN>) {
        chomp;
        my $line = lc($_);

        # match from beginning
        if ( $s eq substr( $line, 0, $s_length ) ) {
            warn "Prefix streetname match: $street\n" if $debug >= 2;
            push( @data, &get_coords($_) );
        }

        last if scalar(@data) >= $limit * 50;
    }

    close IN;

    warn "data: ", join( " ", @data ), " data2: ", join( " ", @data2 ), "\n"
      if $debug >= 2;
    return ( \@data, \@data2 );
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
    my $limit =
      ( length($street) <= 3 ? $max_suggestions_short : $max_suggestions );

    my $street_plain = $street;
    my $street_re    = $street;
    $street_re =~ s/([()|{}\]\[])/\\$1/;

    my $file =
      $city eq 'bbbikeXXX'
      ? "../data/$opensearch_file"
      : "$opensearch_dir/$city/$opensearch_file";

    my ( $d, $d2 ) = &street_match( $file, $street_plain, $limit );

    # no prefix match, try again with prefix match only
    if ( defined $d && scalar(@$d) == 0 && scalar(@$d2) == 0 ) {
        ( $d, $d2 ) = &street_match( $file, $street_plain, $limit, 0 );
    }
    if ( defined $d && scalar(@$d) == 0 && scalar(@$d2) == 0 ) {
        ( $d, $d2 ) = &street_match( $file, "^$street_re", $limit );
    }

    my @data  = defined $d  ? @$d  : ();
    my @data2 = defined $d2 ? @$d2 : ();

    warn "Len1: ", scalar(@data), " ", join( " ", @data ), "\n" if $debug >= 2;
    warn "Len2: ", scalar(@data2), " ", join( " ", @data2 ), "\n"
      if $debug >= 2;

    # less results
    if ( scalar(@data) + scalar(@data2) < $limit ) {
        return ( @data, @data2 );
    }

    # trim results, exact matches first
    else {

        # match words
        my @d;
        @d = grep { /$street_re\b/i || /\b$street_re/ } @data2;  # if $len >= 3;

        my @result = &strip_list( $limit, @data );
        push @result,
          &strip_list(
            $limit / ( scalar(@data) ? 2 : 1 ),
            ( scalar(@d) ? @d : @data2 )
          );
        return @result;
    }
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

sub escapeQuote {
    my $string = shift;

    $string =~ s/"/\\"/g;

    return $string;
}

sub street_coord {
    my $string = shift;

    my ( $street, $coord ) = split "\t", $string;

    $coord =~ s/^\S+\s+//;
    return $street . "\t" . $coord;
}

######################################################################
# GET /w/api.php?namespace=1&q=berlin HTTP/1.1
#
# param alias: q: query, search
#              ns: namespace
#

my $q = new MyCgiSimple;

my $action = 'opensearch';
my $street =
     $q->param('search')
  || $q->param('query')
  || $q->param('q')
  || 'Allschwilerstr';

#|| 'Landsberger Allee (12681)';
# || 'Garibaldistr. (13158)';

if ($force_utf8) {
    require Encode;
    $street = Encode::decode( "utf-8" => $street );
}

# mapping: old street => new street
my ( $street_old, $street_new );
my $street_original = $street;
if ( $street =~ /^(.*?)\s+[\-=]>\s+(.*)/ ) {
    $street_old = $1;
    $street_new = $2;
    $street     = $street_new;

    warn "old street: $street_old, new street: $street_new, street: $street\n"
      if $debug >= 1;
}

my $city      = $q->param('city')      || 'Basel';
my $namespace = $q->param('namespace') || $q->param('ns') || '0';

# untaint
$city      = ( $city      =~ /^([A-Za-z]+$)/    ? $1 : "Berlin" );
$namespace = ( $namespace =~ /^([A-Za-z0-9]+$)/ ? $1 : "0" );
if ( $street =~ /^(.+)$/ ) {
    $street = $1;
}

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

my @list =
  sort &streetnames_suggestions_unique( 'city' => $city, 'street' => $street );
my @suggestion = @list;
@suggestion = map { s/^[^\t]*\t\S+\s+//; $_ } @suggestion;

if ( $debug >= 0 && scalar(@suggestion) <= 0 ) {
    warn "$0: City $city: $street no coords found!\n";
}
warn "$0: City $city: $street", join( " ", @suggestion ), "\n" if $debug >= 2;

# plain text
if ( $namespace eq 'plain' || $namespace == 1 ) {
    print join( "\n", @suggestion ), "\n";
}

# devbridge autocomplete
elsif ( $namespace eq 'dbac' || $namespace == 2 ) {
    print qq/{ query:"/, escapeQuote($street), qq/", suggestions:[/;
    print '"', join( '","', map { escapeQuote($_) } @suggestion ), '"'
      if scalar(@suggestion) > 0;
    print "] }";
}

# googe like, with street name
elsif ( $namespace eq 'google-streetnames' || $namespace == 3 ) {
    print qq/["$street_original",[/;
    print qq{"}, join( '","', map { escapeQuote( street_coord($_) ) } @list ),
      qq{"}
      if scalar(@list) > 0;
    print qq,]],;
}

# googe like
else {
    print qq/["$street",[/;
    print qq{"}, join( '","', map { escapeQuote($_) } @suggestion ), qq{"}
      if scalar(@suggestion) > 0;
    print qq,]],;
}

