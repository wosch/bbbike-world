#!/bin/sh
# Copyright (c) 2014-2014 Wolfram Schneider, http://bbbike.org
#
# srtm-merge - merge SRTM based *.osm.gz files into one big srtm.osm.pbf
#
# a) 34828.78user 3143.18system 3:33:34elapsed 296%CPU (0avgtext+0avgdata 196228maxresident)k
# b) 88568.14user 4809.21system 7:21:50elapsed 352%CPU (0avgtext+0avgdata 979784maxresident)k
# c) 85480.01user 51969.47system 8:36:39elapsed 443%CPU (0avgtext+0avgdata 1087376maxresident)k


set -e

dir=osm
nice='nice -n 15 time'
max_cpu=2

# upgrade to OSM 0.6
# 3.5h
osm-upgrade.pl --out-dir=$dir $@ > a.sh
$nice xargs -0 -n1 -P${max_cpu} /bin/sh -c < a.sh > a.log 2>&1

# convert to *.pbf files
# 7.5h
cd $dir
ls *.osm.gz | $nice xargs -n1 -P${max_cpu} ov2pbf > b.log 2>&1

# merge *.pbf files into one big file
# 8.5h
pbf-merge.pl *.pbf  | perl -npe 's/\n/\0/' > c.sh
$nice xargs -0 -n1 /bin/sh -c < c.sh > c.log 2>&1
