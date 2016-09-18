#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

use Test::More;

use strict;
use warnings;

my @path = qw( . /etc/munin $HOME/.openstreetmap);

plan tests => scalar(@path);

sub stale_symlinks {
    my $path    = shift;
    my $message = shift;

    my $prog =
        q[ find ]
      . $path
      . q[ -type l -print0 | perl -0e 'while(<>) { next if m,^\./tmp/,; if (! -e $_) { print "$_\n"; $exit=1}}; exit $exit' ];
    system($prog);
    is( $?, 0, "stale symlinks in $path" );
}

#######################################################
# main

foreach my $path (@path) {
    stale_symlinks($path);
}

__END__
