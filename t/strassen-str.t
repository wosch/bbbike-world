#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Getopt::Long;
use Data::Dumper qw(Dumper);
use Test::More;
use File::Temp qw(tempfile);
use IO::File;
use Digest::MD5 qw(md5_hex);
use File::stat;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

plan tests => 3;

my $strassen = 'world/t/data-osm/Berlin/strassen';
my $str      = 'world/t/data-osm/Berlin/str';

sub md5_file {
    my $file = shift;
    my $fh = new IO::File $file, "r";
    die "open file $file: $!\n" if !defined $fh;

    my $data;
    while (<$fh>) {
        $data .= $_;
    }

    $fh->close;

    my $md5 = md5_hex($data);
    return $md5;
}

######################################################################

my $tempfile = File::Temp->new( SUFFIX => ".str" );
my $st = 0;

system(qq[cp $strassen $tempfile]);
system(qq[world/bin/strasse-str $tempfile]);
is( $?, 0, "strassen-str converter" );
is( md5_file($str), md5_file($tempfile), "compare output" );

$st = stat($tempfile);
my $size     = $st->size;
my $min_size = 12_000;
cmp_ok( $size, '>', $min_size, "$tempfile: $size > $min_size" );

unlink "$tempfile.bak";

__END__
