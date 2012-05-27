#!/usr/local/bin/perl
# Copyright (c) 2012 Wolfram Schneider, http://bbbike.org
#
# extract-lnglat.pl - split the planet.osm into 360x180 lng,lat data tiles
#
# usage: extract-lng-lat.pl > shell.sh

# Aachen:::de::5.88 50.60 6.58 50.99:294951::

for ( -180 .. 180 ) {
    $a = $_ + 1;

    print
      qq[make -f Makefile.osm CITIES_FILE=tmp/cities_${_}.txt],
      qq[ CITIES_DB=tmp/cities_${_}.csv],
      qq[ OSM_DIR=tmp/osm-latlng ],
qq[ OSM_PLANET_PBF=tmp/osm-lng/p_${_}_-89_${a}_89/p_${_}_-89_${a}_89.osm.pbf ],
      qq[cities-pbf > tmp/log.extract-latlng.$_\n];
}

# ( cd tmp/osm-latlng; find . -name '*.pbf' | xargs du -k |sort -n | perl -npe 's,\./[\d\-]+/p_,,; s,/.*,,; s,_, ,g' ) > tmp/heatmap.csv

