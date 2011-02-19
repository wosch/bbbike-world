#!/usr/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# street-coord.cgi - plot street names on a map as a suggestion service

use MyCgiSimple;

# use warnings make the script 20% slower!
#use warnings;

use strict;

$ENV{LANG} = 'C';

# how many streets to suggestest
my $max_suggestions = 64;

# for the input less than 4 characters
my $max_suggestions_short = 10;

my $opensearch_file = 'opensearch.street-coordinates';
my $opensearch_dir  = '../data-osm';

my $debug = 0;

# word matching for utf8 data
my $force_utf8 = 0;

# look(1) is faster than egrep, override use_egrep option
my $use_look = 1;

sub get_coords {
    my $string = shift;

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

        my @command = ( 'look', $look_opt, $street, $file );

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
      $city eq 'bbbike'
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

my $city = $q->param('city') || 'Basel';
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

my @suggestion =
  map { s/^\S+\s+//; $_ }
  sort &streetnames_suggestions_unique( 'city' => $city, 'street' => $street );

if ( $debug >= 0 && scalar(@suggestion) <= 0 ) {
    warn "City $city: $street no coords found!\n";
}
warn "City $city: $street", join( " ", @suggestion ), "\n" if $debug >= 2;

# plain text
if ( $namespace eq 'plain' || $namespace == 1 ) {
    print join( "\n", @suggestion ), "\n";
}

# devbridge autocomplete
elsif ( $namespace eq 'dbac' ) {
    print qq/{ query:"/, escapeQuote($street), qq/", suggestions:[/;
    print '"', join( '","', map { escapeQuote($_) } @suggestion ), '"'
      if scalar(@suggestion) > 0;
    print "] }";
}

# googe like
else {
    print qq/["$street",[/;
    print qq{"}, join( '","', map { escapeQuote($_) } @suggestion ), qq{"}
      if scalar(@suggestion) > 0;
    print qq,]],;
}

