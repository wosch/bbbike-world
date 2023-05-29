#!/bin/sh
# Copyright (c) 2023-2023 Wolfram Schneider, https://bbbike.org
#
# md5sum.sh - a portable wrapper for md5/md5sum command

PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"; export PATH
PATH="/bin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"; export PATH

md5sum=$(which md5 md5sum 2>/dev/null | head -n 1)
if [ "$md5sum" = "" ];then
  echo "The md5 or md5sum command was not found, give up!" >&2
  exit 1
fi

exec $md5sum "$@"

#EOF
