#!/usr/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# api.cgi - suggestion service for street names

use MyCgiSimple;

# use warnings make the script 20% slower!
#use warnings;

use strict;

$ENV{LANG} = 'C';

# how many streets to suggestest
my $max_suggestions = 64;

# for the input less than 4 characters
my $max_suggestions_short = 10;

my $opensearch_file = 'opensearch.streetnames';
my $opensearch_dir  = '../data-osm';
my $opensearch_dir2 = '../data-opensearch-places';

my $debug          = 1;
my $match_anywhere = 0;
my $match_words    = 1;
my $remove_city    = 1;
my $remove_train   = 1;
my $sort_by_prefix = 1;

# Hauptstr. 27 -> Hauptstr
my $remove_housenumber_suffix = 1;

# Hauptstrassse -> Hauptstr
my $remove_street_abbrevation = 1;

# 232 College Street -> College Street
my $remove_housenumber_prefix = 1;

# word matching for utf8 data
my $force_utf8 = 0;

my $look_command = "/usr/local/bin/look";

# look(1) is faster than egrep, override use_egrep option
my $use_look = 1;

# performance tuning, egrep may be faster than perl regex
my $use_egrep = 1;

sub ascii2unicode {
    my $string = shift;

    my ( $ascii, $unicode, @rest ) = split( /\t/, $string );

    warn "ascii2unicode: $unicode\n" if $debug >= 2;
    return $unicode ? $unicode : $ascii;
}

sub street_sort {
    my %args        = @_;
    my @suggestions = sort @{ $args{'list'} };

    my $prefix = $args{'prefix'};
    my $street = $args{'street'};

    return @suggestions if !$prefix;

    # display street name where the prefix match first
    my @data1;
    my @data2;

    foreach my $s (@suggestions) {
        if ( index( lc($s), lc($street) ) == 0 ) {
            push @data1, $s;
        }
        else {
            push @data2, $s;
        }
    }

    return ( @data1, @data2 );
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

        if ( !open( IN, '-|' ) ) {
            exec @command;
            die "@command: $! :: $?\n";
        }
    }

    elsif ($use_egrep) {
        my @command = ( 'egrep', '-s', '-m', '2000', '-i', $street, $file );

        warn join( " ", @command ), "\n" if $debug >= 2;
        if ( !open( IN, '-|' ) ) {
            exec @command;
            die "@command: $! :: $?\n";
        }
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
            push( @data, &ascii2unicode($_) );
        }

        elsif ( $match_words && /\b$street/i ) {
            warn "Word streetname match: $street\n" if $debug >= 2;
            push( @data, &ascii2unicode($_) );
        }

        # or for long words anyware, second class matches
        elsif ( $match_anywhere && $len >= 2 && /$s/ ) {
            warn "Anywhere streetname match: $street\n" if $debug >= 2;
            push( @data2, &ascii2unicode($_) ) if scalar(@data2) <= $limit * 90;
        }

        last if scalar(@data) >= $limit * 50;
    }

    close IN;

    warn "data: ", join( " ", @data ), " data2: ", join( " ", @data2 ), "\n"
      if $debug >= 2;
    return ( \@data, \@data2 );
}

sub streetnames_suggestions_unique {
    my %args = @_;

    my @list = &streetnames_suggestions(@_);

    # return unique list
    my %hash = map { $_ => 1 } @list;
    @list = keys %hash;

    return street_sort(
        'list'   => \@list,
        'prefix' => $sort_by_prefix,
        'street' => $args{'street'}
    );
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

    if ( !-f $file && -f "$opensearch_dir2/$city/$opensearch_file" ) {
        $file = "$opensearch_dir2/$city/$opensearch_file";
    }

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

my $test_street = "kurz";         #'Zähringe';
my $action      = 'opensearch';
my $street =
     $q->param('search')
  || $q->param('query')
  || $q->param('q')
  || $test_street;

my $city = $q->param('city') || 'Berlin';
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
  &streetnames_suggestions_unique( 'city' => $city, 'street' => $street );

# strip english style addresses with
#    <house number> <street name>
# and run the query again if nothing was found
if (   $remove_housenumber_prefix
    && scalar(@suggestion) == 0
    && $street =~ /^\d+\s+/ )
{
    my $street2 = $street;
    $street2 =~ s/^\d+\s+//;

    if ( $street2 ne "" ) {
        warn "API: city: $city, housenumber prefix: $street <=> $street2\n"
          if $debug;
        @suggestion = &streetnames_suggestions_unique(
            'city'   => $city,
            'street' => $street2
        );
    }
}

# strip european style addresses with
#    <street name> < housenumber
# and run the query again if nothing was found
elsif ($remove_housenumber_suffix
    && scalar(@suggestion) == 0
    && $street =~ /\s+\d+$/ )
{
    my $street2 = $street;
    $street2 =~ s/\s+\d+$//;

    if ( $street2 ne "" ) {
        warn "API: city: $city, housenumber suffix: $street <=> $street2\n"
          if $debug;
        @suggestion = &streetnames_suggestions_unique(
            'city'   => $city,
            'street' => $street2
        );
    }
}

# Hauptstrassse -> Hauptstr
# German only
elsif ($remove_street_abbrevation
    && scalar(@suggestion) == 0
    && $street =~ /[sS]tras?s?e?$/ )
{
    my $street2 = $street;
    $street2 =~ s/([sS]tr)as?s?e?$/$1/;

    if ( $street2 ne "" ) {
        warn "API: city: $city, streetname abbrevation: $street <=> $street2\n"
          if $debug;
        @suggestion = &streetnames_suggestions_unique(
            'city'   => $city,
            'street' => $street2
        );
    }
}

# strip S-Bahn => S, U-Bahn => U
elsif ($remove_train
    && scalar(@suggestion) == 0
    && $street =~ /^([sur])[\s\-]+(train\s+|bahn\s+|bahnof\s+)?(.*)/oi )
{
    my $street2 = "$1 $3";

    warn "API: city: $city, train station: $street <=> $street2\n" if $debug;
    @suggestion = &streetnames_suggestions_unique(
        'city'   => $city,
        'street' => $street2
    );
}

if (   $remove_city
    && scalar(@suggestion) == 0
    && $street =~ /^.*?,\s*/ )
{
    my $street2 = $street;
    $street2 =~ s/^.*?,\s*//;

    if ( $street2 ne "" ) {
        warn "API: city: $city, strip city: $street <=> $street2\n" if $debug;
        @suggestion = &streetnames_suggestions_unique(
            'city'   => $city,
            'street' => $street2
        );
    }
}

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

