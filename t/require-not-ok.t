#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

use Test::More;

use strict;
use warnings;


######################################################################
# we don't want some perl modules on the machine
#
plan tests => 1; 

ok !eval { require Apache::Session }, "Apache::Session";
#ok !eval { require Test::More }, "Test::More";

__END__
