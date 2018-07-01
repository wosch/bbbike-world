#!/bin/sh
# Copyright (c) 2018-2018 Wolfram Schneider, https://bbbike.org
#
# planet-osm-size - display size of planet.osm for PBF and OSM formats
#
# ./planet-osm-size.sh 
# PBF size: 40.5679 GB
# OSM size: 67.5584 GB
#

pbf_size ()
{
    size=$(curl -D /dev/stdout -sSf -X HEAD https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf 2>/dev/null | egrep Content-Length: | awk '{ print $2/1024/1024/1024 }')
    echo "PBF size: $size GB"
}

osm_size ()
{
    size=$(curl -D /dev/stdout -sSfL -X HEAD https://planet.openstreetmap.org/planet/planet-latest.osm.bz2 2>/dev/null | egrep Content-Length: | awk '{ print $2/1024/1024/1024 }')
    echo "OSM size: $size GB"
}

xml_size ()
{
    size=$(curl -L -sSf https://planet.osm.org/planet/planet-latest.osm.bz2 | nice -n 15 pbzip2 -d | wc -c )
    echo "XML size: $size GB"
}


pbf_size
osm_size

