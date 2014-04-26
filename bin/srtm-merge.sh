#!/bin/sh
# Copyright (c) 2014-2014 Wolfram Schneider, http://bbbike.org
#
# srtm-merge - merge SRTM based *.osm.gz files into one big srtm.osm.pbf

set -e

dir=osm
nice='nice -n 15 time'
max_cpu=2

osm-upgrade.pl --out-dir=$dir $@ > a.sh
$nice xargs -0 -n1 -P${max_cpu} /bin/sh -c < a.sh > a.log 2>&1

cd $dir
ls *.osm.gz | $nice xargs -n1 -P${max_cpu} ov2pbf > b.log 2>&1

pbf-merge.pl *.pbf  | perl -npe 's/\n/\0/' > c.sh
$nice xargs -0 -n1 /bin/sh -c < c.sh > c.log 2>&1




