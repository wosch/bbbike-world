#!/bin/sh
# Copyright (c) Jul 2021-2021 Wolfram Schneider, https://bbbike.org
#
# planet-update-cron - wrapper for planet-update called by a cron job
#

PATH=/usr/local/bin:/bin:/usr/bin; export PATH 
set -e

cd $HOME/projects/bbbike

if time nice -n 6 make planet-update sub-planet-daily > tmp/log.planet-update 2>&1; then
  exit 0
else
  echo "planet update failed: $?"
  echo ""
  cat tmp/log.planet-update
  exit 1
fi

