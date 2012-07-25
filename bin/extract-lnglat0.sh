#!/bin/sh

: ${HEATMAP_DIR="heatmap"}

for i in `perl -e 'for (-180 .. 179) { print "$_ " }'`
do
  ./world/bin/extract-lnglat0.pl $i > $HEATMAP_DIR/cities_$i.csv
  awk -F: '{ print $1 } ' $HEATMAP_DIR/cities_$i.csv > $HEATMAP_DIR/cities_$i.txt
done

