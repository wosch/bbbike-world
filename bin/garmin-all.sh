#!/bin/bash
# Copyright (c) Apr 2018 Wolfram Schneider, https://bbbike.org
#
# garmin-all - convert the planet to garmin styles
#

: ${DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"}
: ${garmin_formats="onroad-ascii cycle-ascii leisure-ascii openfietslite-ascii opentopo-ascii oseam-ascii osm-ascii"}

#: ${garmin_regions="antarctica-latest.osm.pbf australia-oceania-latest.osm.pbf"}
: ${garmin_regions="antarctica-latest.osm.pbf australia-oceania-latest.osm.pbf africa-latest.osm.pbf central-america-latest.osm.pbf south-america-latest.osm.pbf asia-latest.osm.pbf north-america-latest.osm.pbf europe-latest.osm.pbf"}

set -e
set -o pipefail # bash only

download_region ()
{
  region="$1"
  url="$DOWNLOAD_URL_PREFIX/$region"
  if [ ! -e $region ]; then
    curl -sSf -L "$url" | osmconvert --drop-author --drop-version --out-pbf - > $region.tmp
    mv -f $region.tmp $region
  fi
}

for region in $garmin_regions
do
  for format in $garmin_formats
  do

    echo "region=$region format=$format"
    download_region $region
    env osm2xxx_max_jobs="4" pbf2osm_max_cpu_time=72000 max_file_size_garmin=59950000 \
	BBBIKE_TMPFS=/bbbike/tmp \
        nice -15 time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-${format} $region
  done
done

