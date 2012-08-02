#!/bin/sh

: ${TILES_DIR="tiles"}

for i in `perl -e 'for (-180 .. 179) { print "$_ " }'`
do
  ./world/bin/extract-lnglat0.pl $i > $TILES_DIR/cities/cities_$i.csv
  awk -F: '{ print $1 } ' $TILES_DIR/cities/cities_$i.csv > $TILES_DIR/cities/cities_$i.txt
done

