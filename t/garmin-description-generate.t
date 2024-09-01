#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2024 Wolfram Schneider, https://bbbike.org

use Test::More;
use IO::File;
use File::Basename;
use File::stat;
use File::Temp qw(tempfile);

use strict;
use warnings;

my @description_files = qw/hongkong.txt numbers.txt/;
my @description_files_extra =
  qw/bangkok.txt hongkong.txt lodz.txt numbers.txt osaka.txt sofia.txt taiwan.txt/;

my $status = 0;

sub read_file_raw {
    my $file = shift;

    my $fh = new IO::File $file, "r";
    die "open file '$file': $!\n" if !defined $fh;
    binmode( $fh, ":raw" );

    my $data;
    while (<$fh>) {
        $data .= $_;
    }
    $fh->close;

    return $data;
}

sub garmin_description {
    my $city  = shift;
    my $limit = shift // 49;

    my $dirname = dirname($0);
    my $script  = "$dirname/../bin/garmin-description-limit.pl";

    my $file = "$dirname/data-utf8/$city";

    my $st   = stat($file) or die "no $file: $!";
    my $size = $st->size;

    my $tmp      = File::Temp->new( SUFFIX => '.garmin-description' );
    my $tempfile = $tmp->filename;

    system("env GARMIN_DESCRIPTION_LIMIT=$limit $script < $file > $tempfile");
    is( $?, $status, "valid description for city=$city" );
    $st = stat($tempfile) or die "no $tempfile $!";

    cmp_ok( $st->size, "<=", $limit,
        "size is less or equal for city=$city limit=$limit" );
}

###############################################################3
# main
push @description_files, @description_files_extra;

for my $limit (qw/1 4 16 32 49 50 51 70/) {
    foreach my $city (@description_files) {
        &garmin_description( $city, $limit );
    }
}

done_testing;

__END__
