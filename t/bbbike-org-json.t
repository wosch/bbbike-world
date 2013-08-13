#!/usr/local/bin/perl
# Copyright (c) Oct 2012-2013 Wolfram Schneider, http://bbbike.org

BEGIN { }

use FindBin;
use lib ( "$FindBin::RealBin/..", "$FindBin::RealBin/../lib",
    "$FindBin::RealBin", );

use Test::More;
use IO::Dir;
use Data::Dumper;
use JSON;

use strict;
use warnings;

my $debug = 1;

my @json_dirs = qw(ext/BBBikeXS ext/Strassen-Inline ext/Strassen-Inline2
  ext/StrassenNetz-CNetFile ext/VectorUtil-Inline ext/VirtArray
  world/t/extract/confirmed world/t/extract/json world/t/extract/json-large world/etc/extract);

my @json_files = get_json_files(@json_dirs);
plan tests => scalar(@json_files);

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

# read a json (or perl) array from file into perl scalar
sub get_json_from_file {
    my $file = shift;

    local $/;
    open( my $fh, '<', $file ) or die "open $file: $!\n";

    my $perl = decode_json(<$fh>);

    return $perl;
}

sub validate {
    my $file = shift;
    my $max  = shift || 1024;
    my $same = '0.001';

    my $poly = get_json_from_file($file);
    isnt( $poly, undef, "valid json" );

    print Dumper($poly) if $debug >= 2;
}

######################################################################
foreach my $file (@json_files) {
    validate($file);
}

__END__
