#!/bin/sh
# Copyright (c) 2018-2024 Wolfram Schneider, https://bbbike.org
#
# planet-osm-size - display size of planet.osm for PBF and OSM formats
#
# ./planet-osm-size.sh
# PBF size:   51.6 GB
# OSM size:   90.7 GB
# XML size: 1256.2 GB
#

set -e
PATH="/bin:/usr/bin:/usr/local/bin"; export PATH

# https://planet.openstreetmap.org
: ${osm_server="https://ftp5.gwdg.de/pub/misc/openstreetmap/planet.openstreetmap.org"}
: ${curl_opt="-sSf --connect-timeout 5 -m 36000"}

pbf_size ()
{
    curl $curl_opt -D /dev/stdout -L --head \
	$osm_server/pbf/planet-latest.osm.pbf 2>/dev/null | \
	egrep -i '^Content-Length: ' | head -n 1 | \
        awk '{ printf("PBF size:     %6.1f GB\n", $2 / 1024 /1024 / 1024) }'
}

osm_size ()
{
    curl $curl_opt -D /dev/stdout -L --head \
	$osm_server/planet/planet-latest.osm.bz2 2>/dev/null | \
	egrep -i '^Content-Length: ' | head -n 1 | \
	awk '{ printf("OSM.bz2 size: %6.1f GB\n", $2 / 1024 /1024 / 1024) }'
}

xml_size ()
{
    curl $curl_opt -L $osm_server/planet/planet-latest.osm.bz2 | \
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

echo ""

#EOF
