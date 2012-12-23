#!/bin/sh
# Copyright (c) 2012-2013 Wolfram Schneider, http://bbbike.org

set -e
: ${TILES_DIR="tile"}
mkdir -p $TILES_DIR/lng

for i in `perl -e 'for (-180 .. 179) { print "$_ " }'`
do
  ./world/bin/tile-lnglat0.pl $i > $TILES_DIR/cities/cities_$i.csv
  awk -F: '{ print $1 } ' $TILES_DIR/cities/cities_$i.csv > $TILES_DIR/cities/cities_$i.txt
  mkdir -p $TILES_DIR/lnglat/$i
done

