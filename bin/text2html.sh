#!/bin/sh
# Copyright (c) 2013-2018 Wolfram Schneider, https://bbbike.org
#
# text2html - convert a README.txt to README.html
#
# usage: ./text2html < README.txt > README.html

#set -e
PATH=/usr/local/bin:/bin:/usr/bin; export PATH

(
  echo "<html><head><title>README</title></head><body><pre>"
  perl -npe ' s/\&/&amp;/g; s/</&lt;/g; s/>/&gt;/g;  s,(https?://\S+),<a href="$1">$1</a>,gi' $1
  echo "</pre></body></html>"
) | tidy -wrap -raw -i /dev/stdin 2>/dev/null |
    perl -npe 's,^  <meta name="generator" content="HTML Tidy.*\n,  <meta http-equiv="content-type" content="text/html; charset=utf-8">,'

exit 0
