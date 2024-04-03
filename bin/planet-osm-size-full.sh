#!/bin/sh
# Copyright (c) 2018-2024 Wolfram Schneider, https://bbbike.org
#
# planet-osm-size-full - display size of planet.osm/full for PBF and OSM formats
#                        this includes the full history of OSM
#
# ./planet-osm-size-full.sh
# Running at date: 2024-04-01
#
# PBF size:      125.7 GB
# OSM.bz2 size:  211.4 GB
# XML size:     3795.6 GB
#

set -e
PATH="/bin:/usr/bin:/usr/local/bin"; export PATH

# https://planet.openstreetmap.org
: ${osm_server="https://ftp5.gwdg.de/pub/misc/openstreetmap/planet.openstreetmap.org"}

pbf_size ()
{
    curl -D /dev/stdout -sSfL --head \
	$osm_server/pbf/full-history/history-latest.osm.pbf 2>/dev/null | \
	egrep -i '^Content-Length: ' | head -n 1 | \
        awk '{ printf("PBF size:     %6.1f GB\n", $2 / 1024 /1024 / 1024) }'
}

osm_size ()
{
    curl -D /dev/stdout -sSfL --head \
	$osm_server/planet/full-history/history-latest.osm.bz2 2>/dev/null | \
	egrep -i '^Content-Length: ' | head -n 1 | \
	awk '{ printf("OSM.bz2 size: %6.1f GB\n", $2 / 1024 /1024 / 1024) }'
}

xml_size ()
{
    curl -L -sSf $osm_server/planet/full-history/history-latest.osm.bz2 | \
	nice -n 15 pbzip2 -d | wc -c | \
        awk '{ printf("XML size:     %6.1f GB\n", $1 / 1024 / 1024 / 1024) }'
}

##############################################################################
#
echo "Please update me: https://wiki.openstreetmap.org/wiki/Planet.osm/full" 
echo ""
echo "Running at date: $(date '+%Y-%m-%d')"
echo ""

pbf_size
osm_size
xml_size

echo ""

#EOF
