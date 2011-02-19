#!/usr/local/bin/perl
# Copyright (c) 2009-2011 Wolfram Schneider, http://bbbike.org
#
# look.pl - implement look(1) in perl
#

use Search::Dict;
use IO::File;

use strict;
use warnings;

sub usage { return "usage $0 string file\n"; }

my $string = $ARGV[0] or die usage;
my $file   = $ARGV[1] or die usage;

my $fh = IO::File->new($file) or die "open $file: $!\n";

my $coord = $string;

look( $fh, $coord, 0, 0 ) or die "look: $!\n";

my $line = <$fh>;
print $line if defined $line;

