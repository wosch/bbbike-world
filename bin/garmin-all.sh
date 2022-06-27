#!/bin/bash
# Copyright (c) Apr 2018-2022 Wolfram Schneider, https://bbbike.org
#
# garmin-all - convert the planet to garmin styles
#

: ${DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"}
: ${garmin_formats="ontrail-latin1"}

#: ${garmin_regions="antarctica australia-oceania"}
: ${garmin_regions="antarctica australia-oceania africa central-america south-america asia north-america europe"}

set -e
set -o pipefail # bash only

download_region ()
{
  region="$1"
  url="$DOWNLOAD_URL_PREFIX/$region-latest.osm.pbf"
  curl --connect-timeout 10 -sSf -L "$url" | osmconvert --drop-author --drop-version --out-pbf - > $region.tmp
  mv -f $region.tmp $region.osm.pbf
}

for region in $garmin_regions
do
  echo "region=$region format=$garmin_formats"
  download_region $region
  env osm2xxx_max_jobs="8" pbf2osm_max_cpu_time=72000 max_file_size_garmin=59950000 \
    BBBIKE_TMPFS=/bbbike/tmp \
      nice -15 time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-${garmin_formats} $region.osm.pbf $region
  rm -f $region.osm.pbf
done

