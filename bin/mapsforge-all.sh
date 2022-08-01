#!/bin/bash
# Copyright (c) Apr 2018-2022 Wolfram Schneider, https://bbbike.org
#
# garmin-all - convert the planet to garmin styles
#

set -e
set -o pipefail # bash only

PATH="/usr/local/bin:/bin:/usr/bin"; export PATH

: ${DOWNLOAD_URL_PREFIX="https://download.geofabrik.de"}
: ${BBBIKE_TMPDIR="/bbbike/tmp"}
: ${BBBIKE_TMPFS="/tmp"}

: ${regions="antarctica"}
: ${max_days="8"}
: ${nice_level="13"}

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
  $debug && echo "region=$region"
  sub_region=$(basename $region)
  continent=$(dirname $region)

  (
    mkdir -p $continent
    cd $continent

    if [ $(ls $sub_region.osm.mapsforge-*.zip 2>/dev/null | wc -l) -gt 0 -a $(find $sub_region.osm.mapsforge-*.zip -mtime -${max_days} 2>/dev/null | wc -l) -gt 0 ]; then
      $debug && echo "already exists '$region'"
    elif download_region $region $sub_region; then
      env OSM_CHECKSUM=false pbf2osm_max_cpu_time=14400 \
        nice -n $nice_level $time $HOME/projects/bbbike/world/bin/pbf2osm --mapsforge-osm $sub_region.osm.pbf $region || exit_status=1
      rm -f $sub_region.osm.pbf
    else
      echo "could not download $url - skip"
      exit_status=2
    fi
  )
done

exit $exit_status

#EOF
