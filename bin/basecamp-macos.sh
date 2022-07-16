#!/bin/sh
# Copyright (c) 2022 Wolfram Schneider, https://extract.bbbike.org
#
# basecamp-macos.sh - installer on MacOS for Garmin Basecamp
#
# The script converts a gmapsupp.img file into a MacOS disk image which
# will be automatically recognised by Garmin Basecamp. This allows you
# to use Basecamp on MacOS without a connected Garmin device or SD card.
#
# Please open this script with the MacOS Terminal App
#   Finder -> Open With ->  Other -> Enable=All Applications -> Terminal -> open 
#
# or inside an open Terminal in this unzip'd extract folder with 
#
# $ ./basecamp-macos.sh
#
# see also https://extract.bbbike.org/garmin.html

set -e

called_from_finder=false
test $HOME = $(pwd) && called_from_finder=true

$called_from_finder && cd $(dirname $0)

# use a unique id for mount point
id=$(sed -E -n -e 's/.* --mapid=([0-9][0-9][0-9][0-9]).*/\1/p' logfile.txt)
image=BBBikeBaseCamp${id}.dmg

rm -rf $image garmin

if du -ks gmapsupp.img | awk '{ if ($1 >= 4*1024*1024) { exit(1) }}'; then
  echo "This script may run some seconds or minutes depending on the image size"
else
  echo "The Garmin image gmapsupp.img is larger than 4GB which is not supported by Garmin Basecamp."
  echo "Please connect your Garmin device or use an SD card. Sorry!"
  exit 1
fi

mkdir garmin
( cd garmin && ln -s ../gmapsupp.img .)

# only FAT32 filesystem works reliable for Garmin (sic!)
hdiutil create $image -ov -volname "BBBike${id}" -fs FAT32 -srcfolder .
hdiutil attach -quiet $image


cat <<EOF

Now start Garmin Basecamp if you don't have already

and allow to access the new /Volumes/BBBike${id}

Garmin Basecamp will automatically recognise the map. Select the
map and zoom in.

Have fun and thanks for using https://extract.bbbike.org 

EOF

# show the message for some seconds in a non-interactive terminal
$called_from_finder && sleep 20

#EOF
