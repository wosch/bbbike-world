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
: ${max_days="8"}
: ${nice_level="13"}
: ${curl_opt=""}
: ${pbf2osm_max_cpu_time="28800"}
: ${osm2xxx_max_jobs="8"}
: ${max_file_size_garmin="59950000"}

: ${debug=false}
$debug && time="time"

download_file ()
{
  url=$1
  tmp=$2

  curl --connect-timeout 5 --retry 10 --max-time 200 $curl_opt -sSf -L "$url" | \
    nice -n $nice_level osmium cat --overwrite -o $tmp -Fpbf -fpbf,add_metadata=false
}

download_region ()
{
  region="$1"
  sub_region="$2"
  tmpdir=$3

  tmp=$(mktemp $tmpdir/$sub_region.XXXXXXXX.tmp)
  url="$DOWNLOAD_URL_PREFIX/$region-latest.osm.pbf"

  download_file $url $tmp
  mv -f $tmp $tmpdir/$sub_region.osm.pbf
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
    tmpdir=$(mktemp -d $BBBIKE_TMPDIR/garmin-all-$sub_region.XXXXXXXXXX.tmp)

    if [ $(ls $sub_region.osm.garmin-*.zip 2>/dev/null | wc -l) -gt 0 -a $(find $sub_region.osm.garmin-*.zip -mtime -${max_days} 2>/dev/null | wc -l) -gt 0 ]; then
      $debug && echo "already exists '$region'"
    elif download_region $region $sub_region $tmpdir; then
      $debug && echo "osm2xxx_max_jobs=$osm2xxx_max_jobs pbf2osm_max_cpu_time=$pbf2osm_max_cpu_time area size: $(cd $tmpdir && du -hs $sub_region.osm.pbf)"
      if env osm2xxx_max_jobs=$osm2xxx_max_jobs OSM_CHECKSUM=false pbf2osm_max_cpu_time=$pbf2osm_max_cpu_time max_file_size_garmin=$max_file_size_garmin BBBIKE_TMPFS=/tmp \
         nice -n $nice_level $time $HOME/projects/bbbike/world/bin/pbf2osm --garmin-${garmin_formats} $tmpdir/$sub_region.osm.pbf $region
      then
        mv -f $tmpdir/$sub_region.*zip .
      else
        exit_status=1
      fi
    else
      echo "could not download $region - skip"
      exit_status=2
    fi

    rm -rf $tmpdir
  )
done

exit $exit_status

#EOF

