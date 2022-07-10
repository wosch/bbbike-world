#!/bin/bash
# Copyright (c) Apr 2018-2022 Wolfram Schneider, https://bbbike.org
#
# garmin-all - convert the planet to garmin styles
#

set -e
set -o pipefail # bash only

PATH="/usr/local/bin:/bin:/usr/bin"; export PATH

: ${DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"}
: ${garmin_formats="ontrail-latin1:bbbike-latin1:openfietslite-latin1"}

#: ${garmin_regions="antarctica australia-oceania"}
: ${garmin_regions="antarctica australia-oceania africa central-america south-america asia north-america europe"}
: ${nice_level="17"}

: ${debug=false}
$debug && time="time"

download_region ()
{
  region="$1"
  tmp=$(mktemp $region.XXXXXXXX.tmp)
  url="$DOWNLOAD_URL_PREFIX/$region-latest.osm.pbf"
  curl --connect-timeout 10 -sSf -L "$url" | \
    nice -n $nice_level osmium cat --overwrite -o $tmp -Fpbf -fpbf,add_metadata=false
  chmod a+r $tmp
  mv -f $tmp $region.osm.pbf
}

for region in $garmin_regions
do
  $debug && echo "region=$region format=$garmin_formats"
  download_region $region
  env osm2xxx_max_jobs="8" OSM_CHECKSUM=false pbf2osm_max_cpu_time=72000 max_file_size_garmin=59950000 \
    BBBIKE_TMPFS=/tmp \
      nice -n $nice_level $time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-${garmin_formats} $region.osm.pbf $region
  rm -f $region.osm.pbf
done

