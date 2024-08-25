#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2024 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use IO::File;
use File::Basename;

use Test::More::UTF8;

use strict;
use warnings;

#chdir("$FindBin::RealBin/../..") or die "Cannot find bbbike world root directory\n";

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

sub convert {
    my $city  = shift;
    my $limit = shift // 49;
    my $lang  = shift // "en_US.UTF-8";

    my $script = $0;
    $script =~ s/\.t$/.sh/;

    # xxx: avoid endless loop, should never happens
    die "oops: $script\n" if $script eq $0;

    my $dirname = dirname($0);
    my $data    = &read_file_raw("$dirname/data-utf8/$city");

    system(
qq[env LANG="$lang" GARMIN_DESCRIPTION_LIMIT="$limit" garmin_description="$data" $script]
    );
    is( $?, $status,
        "valid description LANG=$lang limit=$limit for city=$city" );
}

###############################################################3
# main
my $long = $ENV{BBBIKE_TEST_LONG} // 0;
my $fast = $ENV{BBBIKE_TEST_FAST} // 0;
push @description_files, @description_files_extra if $long;

# 49 bytes for UTF-8
foreach my $city (@description_files) {
    &convert( $city, 49 );
}

if ( !$fast || $long ) {

    # 50 bytes for UTF-8, ascii only
    &convert( "numbers.txt", 50 );

    # 50 bytes for C
    foreach my $city (@description_files) {
        &convert( $city, 50, "C" );
    }

    if ($long) {

        # 150 bytes for C - must fail
        $status = 256;
        foreach my $city (@description_files) {
            &convert( $city, 150, "C" );
        }
    }
}

done_testing;

__END__
