#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, http://bbbike.org

use Test::More;

use strict;
use warnings;

my @prod = qw(
  /usr/local/www/debian.bbbike.org
  /usr/local/www/download.bbbike.org
  /usr/local/www/bbbike
  /usr/local/www/bbbike.org
  /etc/lighttpd
  /var/lib/bbbike
  /etc/munin
);
my @path = qw( . $HOME/.openstreetmap );

foreach my $dir (@prod) {
    push( @path, $dir ) if -d $dir;
}

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
