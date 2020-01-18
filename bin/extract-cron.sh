#!/bin/sh
# Copyright (c) 2013-2020 Wolfram Schneider, https://bbbike.org
#
# extract-cron.sh - wrapper for extract.pl script 
#
# the subject line contains the exit status

PATH=/bin:/usr/bin; export PATH
: ${BBBIKE_TMPDIR="/bbbike/tmp"}
#set -e

# load standard BBBike extract config
if [ -f $HOME/.bbbikerc ]; then
    . $HOME/.bbbikerc
fi

log_output=/var/tmp/extract.log
prog=$(echo $0 | perl -npe 's/-cron\.sh$/.pl/')
subject="bbbike extract status:"

case $BBBIKE_EXTRACT_PROFILE in
    *extract-pro* ) subject="bbbike extract pro status:";;
esac

tmp=$(mktemp ${BBBIKE_TMPDIR}/extract.XXXXXXXXXXX)

##############################################################
# run the real script
#
$prog --debug=1 "$@" > $tmp 2>&1
error=$?

# it run
if [ -s $tmp ]; then
    mail -s "$subject $error" $(whoami) < $tmp
fi

if [ -n "$log_output" ]; then
   if [ -s $tmp ]; then
      ( echo ""; echo "==> $(date)"; cat $tmp ) >> $log_output
   else
      ( echo "==> $(date)" ) >> $log_output
   fi
fi

rm -f $tmp

