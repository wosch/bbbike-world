#!/bin/sh
# Copyright (c) 2014 Wolfram Schneider, https://bbbike.org
#
# vm-cleanup - cleanup a VirtualBox VM before running export
#

PATH=/bin:/bin:/usr/bin; export PATH

# debian package cleanup
sudo apt-get clean

# redhat package cleanup
sudo yum clean all

count=$(df -k /var/tmp | egrep ^/ | awk '{print int($2/1024)}')

file=/var/tmp/swap.fill
dd if=/dev/zero of=$file bs=1M count=$count
rm -f $file


