#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2022 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use utf8;
use Test::More;
use Test::More::UTF8;

#use BBBike::Test;
use Extract::Locale;
use File::stat;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

#our $option = {
#    'language'            => "en",
#    'supported_languages' => [qw/en de fr/],
#    'message_path'        => "../world/etc/extract",
#};

my @lang         = qw/en de es fr ru/;
my $message_path = $Extract::Locale::option->{'message_path'};
$message_path =~ s,^\.\./,,;

# formats with a *.zip tarball
#world/etc/extract/osm2garmin.de.sh
#world/etc/extract/osm2mapsforge.de.sh
#world/etc/extract/osm2organicmaps.de.sh
#world/etc/extract/osm2mbtiles.de.sh
#world/etc/extract/osm2osmand.de.sh
#world/etc/extract/osm2png.de.sh
#world/etc/extract/osm2shape.de.sh
#world/etc/extract/osm2svg.de.sh
my @formats = qw/garmin mapsforge organicmaps mbtiles osmand png shape svg/;

#############################################################################
# main
#

# min. size of a template file
my $min_size = 600;

# check a bunch of template files
foreach my $format (@formats) {
    foreach my $lang (@lang) {
        my $file = "$message_path/osm2$format.$lang.sh";
        my $st = stat($file) or warn "stat: $file\n";

        ok( $st, "file: $file" );

        my $size = $st->size;
        cmp_ok( $size, ">", $min_size, "$file $size > $min_size" );

        system("cat $file > /dev/null");
        is( $?, 0, "can read $file" );

    }
}

plan tests => scalar(@formats) * scalar(@lang) * 3;

#done_testing;

__END__
