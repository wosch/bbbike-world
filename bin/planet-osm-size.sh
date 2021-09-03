#!/bin/sh
# Copyright (c) 2018-2021 Wolfram Schneider, https://bbbike.org
#
# planet-osm-size - display size of planet.osm for PBF and OSM formats
#
# ./planet-osm-size.sh 
# PBF size: 51.6499 GB
# OSM size: 90.7572 GB
# XML size: 1256.26 GB
#

pbf_size ()
{
    size=$(curl -D /dev/stdout -sSfL --head \
	https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf 2>/dev/null | \
	egrep -i Content-Length: | awk '{ printf("%.1f\n", $2/1024/1024/1024) }' )
    echo "PBF size: $size GB"
}

osm_size ()
{
    size=$(curl -D /dev/stdout -sSfL --head \
	https://planet.openstreetmap.org/planet/planet-latest.osm.bz2 2>/dev/null | \
	egrep -i Content-Length: | awk '{ printf("%.1f\n", $2/1024/1024/1024) }' )
    echo "OSM size: $size GB"
}

xml_size ()
{
    size=$(curl -L -sSf https://planet.osm.org/planet/planet-latest.osm.bz2 | \
	nice -n 15 pbzip2 -d | wc -c | awk '{ printf("%.1f\n", $1/1024/1024/1024) }' )
    echo "XML size: $size GB"
}

##############################################################################
#
echo "Please update me: https://wiki.openstreetmap.org/wiki/Planet.osm"
echo ""

pbf_size
osm_size
xml_size

#EOF
