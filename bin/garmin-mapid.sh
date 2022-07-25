#!/bin/sh
# Copyright (c) 2022 Wolfram Schneider, https://extract.bbbike.org
#
# garmin-mapid.sh - extract mapid from extract
#
# usage: ./garmin-mapid.sh *garmin*.zip

set -e
PATH="/usr/local/bin:/bin:/usr/bin"; export PATH
LANG=C; export LANG

validate ()
{
  zip="$1"
  echo $(unzip -p "$zip" '*logfile.txt' | grep -- --mapid | sed -E -n -e 's/.* --mapid=([0-9][0-9][0-9][0-9][0-9]).*/\1/p')
}

for file
do
  case $file in
    *garmin*.zip ) validate "$file" ;;
    * ) ;;
  esac
done | sort | uniq -c | sort -n

#EOF
