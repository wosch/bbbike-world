#!/bin/sh
# Copyright (c) 2018-2022 Wolfram Schneider, https://bbbike.org
#
# planet-osm-size - display size of planet.osm for PBF and OSM formats
#
# ./planet-osm-size.sh
# PBF size:   51.6 GB
# OSM size:   90.7 GB
# XML size: 1256.2 GB
#

pbf_size ()
{
    curl -D /dev/stdout -sSfL --head \
	https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf 2>/dev/null | \
	egrep -i '^Content-Length: ' | head -n 1 | \
        awk '{ printf("PBF size:     %6.1f GB\n", $2 / 1024 /1024 / 1024) }'
}

osm_size ()
{
    curl -D /dev/stdout -sSfL --head \
	https://planet.openstreetmap.org/planet/planet-latest.osm.bz2 2>/dev/null | \
	egrep -i '^Content-Length: ' | head -n 1 | \
	awk '{ printf("OSM.bz2 size: %6.1f GB\n", $2 / 1024 /1024 / 1024) }'
}

xml_size ()
{
    curl -L -sSf https://planet.osm.org/planet/planet-latest.osm.bz2 | \
	nice -n 15 pbzip2 -d | wc -c | \
        awk '{ printf("XML size:     %6.1f GB\n", $1 / 1024 / 1024 / 1024) }'
}

##############################################################################
#
echo "Please update me: https://wiki.openstreetmap.org/wiki/Planet.osm"
echo ""
echo "Running at date: $(date '+%Y-%m-%d')"
echo ""

pbf_size
osm_size
xml_size

#EOF
