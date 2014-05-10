#!/bin/sh
# Copyright (c) 2013 Wolfram Schneider, http://bbbike.org
#
# extract-cron.sh - wrapper for extract.pl script 
#
# the subject line contains the exit status

PATH=/bin:/usr/bin; export PATH
#set -e

log_output=/var/tmp/extract.log
prog=$(echo $0 | perl -npe 's/-cron\.sh$/.pl/')
subject="bbbike extract status:"

case $BBBIKE_EXTRACT_PROFILE in
    *extract-pro* ) subject="bbbike extract pro status:";;
esac

tmp=$(mktemp -t extract.XXXXXXXXXXX)

$prog --debug=1 $@ > $tmp 2>&1
error=$?

# it run
if [ -s $tmp ]; then
    mail -s "$subject $error" $(whoami) < $tmp
fi

if [ -n "$log_output" ]; then
   cat $tmp >> $log_output
fi

rm -f $tmp

