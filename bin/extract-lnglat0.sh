#!/bin/sh

for i in `perl -e 'for (-180 .. 180) { print "$_ " }'`
do
  ./world/bin/extract-lnglat.pl $i > tmp/cities_$i.csv
  awk -F: '{ print $1 } ' tmp/cities_$i.csv > tmp/cities_$i.txt
done

