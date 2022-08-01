#!/bin/bash
# Copyright (c) Apr 2018-2022 Wolfram Schneider, https://bbbike.org
#
# garmin-all - convert the planet to garmin styles
#

set -e
set -o pipefail # bash only

PATH="/usr/local/bin:/bin:/usr/bin"; export PATH
: ${BBBIKE_TMPDIR="/bbbike/tmp"}
: ${BBBIKE_TMPFS="/tmp"}

: ${DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"}
: ${garmin_formats="ontrail-latin1:bbbike-latin1:openfietslite-latin1"}

#: ${regions="antarctica australia-oceania"}
: ${regions="antarctica australia-oceania africa central-america south-america asia north-america europe"}
: ${nice_level="17"}

: ${debug=false}
$debug && time="time"

download_file ()
{
  url=$1
  tmp=$2

  curl --connect-timeout 10 -sSf -L "$url" | \
    nice -n $nice_level osmium cat --overwrite -o $tmp -Fpbf -fpbf,add_metadata=false
}

download_region ()
{
  region="$1"
  sub_region="$2"

  tmp=$(mktemp $sub_region.XXXXXXXX.tmp)
  url="$DOWNLOAD_URL_PREFIX/$region-latest.osm.pbf"

  if ! download_file $url $tmp; then
    # try it again some seconds later in case of network errors
    sleep 61
    if ! download_file $url $tmp; then
      sleep 181
      download_file $url $tmp
    fi
  fi

  mv -f $tmp $sub_region.osm.pbf
}

exit_status=0
for region in $regions
do
  $debug && echo "region=$region format=$garmin_formats"
  sub_region=$(basename $region)
  continent=$(dirname $region)

  (
    mkdir -p $continent
    cd $continent
    if download_region $region $sub_region; then
      env osm2xxx_max_jobs="8" OSM_CHECKSUM=false pbf2osm_max_cpu_time=72000 max_file_size_garmin=59950000 \
        BBBIKE_TMPFS=/tmp \
          nice -n $nice_level $time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-${garmin_formats} $sub_region.osm.pbf $region || exit_status=1
      rm -f $sub_region.osm.pbf
    else
      echo "could not download $url - skip"
      exit_status=2
    fi
  )
done

exit $exit_status

#EOF

