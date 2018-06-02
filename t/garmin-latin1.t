#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

# wrapper to run garmin-*-latin1 format tests
use File::Basename;
use lib '.';

my $dir = dirname($0);
require "$dir/garmin.t";

