#!/bin/sh
# Copyright (c) Aug 2024-2024 Wolfram Schneider, https://bbbike.org
#
# check garmin description set

set -e

: ${garmin_description=""}

trap 'rm -rf $tmpdir' 0
tmpdir=$(mktemp -d)

dir=$(dirname $0)

file=$dir/data-osm/Oderberg.osm.pbf
file2=$tmpdir/$(basename $file)

cp $file $file2

$dir/../bin/osm2garmin "$file2" osm "$garmin_description osm/UTF-8 BBBike.org 2024-08-24"

#EOF
