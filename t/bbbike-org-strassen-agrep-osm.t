#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org

# Author: Slaven Rezic

use Test::More;
use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib" );
use Strassen::Core;
use Time::HiRes qw( gettimeofday tv_interval );
use Data::Dumper;

use strict;
use warnings;

my $strassen = "data-osm/Berlin/strassen";

BEGIN {
    my $strassen = "data-osm/Berlin/strassen";

    if ( !-r $strassen ) {
        print qq{1..0 # skip '$strassen' does not exists\n};
        print qq{       please run: make CITIES="Berlin" fetch convert\n};
        exit;
    }
}

my @search_types = ( "agrep", "String::Approx", "perl" );

my @streets = (
    [ "Dudenstr",               ["Dudenstr. (10965)"] ],
    [ "garibaldistr",           ["Garibaldistr. (13158)"] ],
    [ "Garibaldi",              ["Garibaldistr. (13158)"] ],
    [ "Really does not exist!", [] ],
);

my $debug = 0;

plan tests => scalar(@streets) * 3;

my $s_utf8 = Strassen->new($strassen);

# agrep or perl
# String::Approx or perl

sub elapsed {
    my $time_start = shift;
    my $elapsed = tv_interval( $time_start, [gettimeofday] );
    return int( $elapsed * 100 ) / 100;
}

for my $search_def (@search_types) {
    local $Strassen::OLD_AGREP;
    my %args;

    if ( $search_def eq 'agrep' ) {

        # OK
    }
    else {
        $Strassen::OLD_AGREP = 1;
        if ( $search_def eq 'String::Approx' ) {

            # OK
        }
        else {
            %args = ( NoStringApprox => 1 );
        }
    }

    for my $encoding_def ( [ $s_utf8, 'utf-8' ] ) {
        my ( $s, $encoding ) = @$encoding_def;

        my $check = sub {
            my ( $supply, $expected ) = @_;
            my $time_start = [gettimeofday];

            local $Test::Builder::Level = $Test::Builder::Level + 1;
            my @result = $s->agrep( $supply, %args );
            warn Dumper( \@result ) if $debug >= 2;

            is_deeply( \@result, $expected,
                    "Search for '$supply' ($search_def, $encoding) in "
                  . &elapsed($time_start)
                  . " seconds" );
        };

        foreach my $test (@streets) {
            $check->(@$test);
        }
    }
}
__END__
