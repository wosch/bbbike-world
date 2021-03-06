#!/usr/local/bin/perl
# Copyright (c) Oct 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use IO::Dir;
use Data::Dumper;
use JSON;
use Math::Polygon::Calc;
use Math::Polygon::Transform;

use Extract::Poly;
use Extract::Utils;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $debug = 1;

my $json_dir       = "world/t/extract/json";
my $json_dir_large = "world/t/extract/json-large";

my @json_files = get_json_files( $json_dir, $json_dir_large );

plan tests => scalar(@json_files) * 4;

sub get_json_files {
    my @dirs = @_;
    my @files;
    foreach my $dir (@dirs) {
        my $dh = IO::Dir->new($dir);
        if ( !defined $dh ) {
            die "open dir '$dir': $!\n";
        }

        while ( defined( my $filename = $dh->read ) ) {
            push @files, "$dir/$filename" if $filename =~ /\.json$/;
        }
    }
    return @files;
}

sub validate {
    my $file = shift;
    my $max  = shift || 1024;
    my $same = '0.001';

    my $extract_utils = new Extract::Utils;
    my $poly          = $extract_utils->parse_json_file($file);
    print "Test file $file, same=$same\n";

    print Dumper($poly) if $debug >= 2;

    # max. 10 meters accuracy
    my @poly = polygon_simplify( 'same' => $same, @$poly );

    # but not more than N points
    if ( scalar(@poly) > $max ) {
        print "Resize 0.01 $#poly\n";
        @poly = polygon_simplify( 'same' => 0.01, @$poly );
        if ( scalar(@poly) > $max ) {
            print "Resize $max points $#poly\n";
            @poly = polygon_simplify( max_points => $max, @poly );
        }
    }

    cmp_ok( scalar(@poly), '<', scalar(@$poly),
        "reduce polygon size: @{[ $#poly + 1]} < @{[ $#$poly + 1]}" );

    my ( $xmin, $ymin, $xmax, $ymax ) = polygon_bbox @$poly;
    like( $xmin, qr/^\-?[0-9]+(\.[0-9]+)?$/, "polygon box: $xmin is float\n" );
    cmp_ok( scalar(@poly), '>',  16,       "more than 16 points" );
    cmp_ok( scalar(@poly), '<=', $max + 1, "less equeal $max points" );

}

######################################################################
foreach my $file (@json_files) {
    validate($file);
}

__END__
