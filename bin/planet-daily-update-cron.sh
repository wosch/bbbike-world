#!/bin/sh
# Copyright (c) Jul 2021-2022 Wolfram Schneider, https://bbbike.org
#
# planet-daily-update-cron - wrapper for planet-daily-update called by a cron job
#

PATH="/usr/local/bin:/bin:/usr/bin"; export PATH
set -e

cd $HOME/projects/bbbike
logfile="tmp/log.planet-daily-update"
touch $logfile

if ( time nice -n 6 make planet-daily-update && time make -j2 sub-planet-daily build-tag-name-db ) > $logfile 2>&1; then
  exit 0
else
  echo "planet update failed: $?"
  echo ""
  cat $logfile
  exit 1
fi

#EOF
