#!/bin/sh
# Copyright (c) 2012-2013 Wolfram Schneider, http://bbbike.org
#
# extract-disk-usage - calculate uncompressed image size for Garmin & Osmand
#

PATH=/usr/local/bin:/bin:/bin:/usr/bin; export PATH

tempfile=$(mktemp);
trap 'rm -f $tempfile' 0 1 2 15

set -e

usage () {
   echo "$@"
   echo ""
   echo "usage: $0 file.zip"
   exit 1
}

file="$1"

test -z "$file" && usage "missing file"
test -f "$file" || usage "file does not exists: '$file'"

case $file in
    *.zip ) ;;
    * ) usage "file is not a zip file: '$file'" ;;
esac

unzip -v $file > $tempfile

perl -e '
    my $counter = 0;
    while(<>) {
        chomp;
        if (m, (planet|Cusco-).*?/(gmapsupp\.img|shape/.*|(planet_|Cusco).*\.(map|obf|bin))$, ) {
            if (/^\s*(\d+)/) {
                $counter += $1;
            }
        }
    }
    print int($counter / 1024 + 0.5), "\n";
' < $tempfile


