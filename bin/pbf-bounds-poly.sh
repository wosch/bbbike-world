#!/bin/sh
# Copyright (c) Sep 2022 Wolfram Schneider, https://bbbike.org
#
# pbf-bounds-poly - extracts bounds from a PBF file as poly config
#

PATH=/bin:/usr/bin:/usr/local/bin; export PATH

usage () {
   echo "$@"
   echo "usage file.pbf"
   exit 1
}

# no spaces in filenames please
file=$1

test -e $file || usage "file '$file' does not exists"

tmpfile=$(mktemp)
osmconvert "$file" 2>/dev/null | head -4 | egrep minlat > $tmpfile

test -s $tmpfile || usage "file '$file': does not contain minlat"
basename=$(basename $file .osm.pbf)

perl -npe 's,[^0-9\.\-]*"([0-9\.\-]+)"[^0-9\."\-]*,$1 ,g' $tmpfile |
perl -ne '($minlat,$minlon, $maxlat, $maxlon) = split; 
  print qq['$basename'
1
   $minlon  $minlat
   $maxlon  $minlat
   $maxlon  $maxlat
   $minlon  $maxlat
END
END
]'

rm -f $tmpfile


#EOF
