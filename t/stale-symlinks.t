#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2017 Wolfram Schneider, https://bbbike.org
#
# check for stale symlinks in given directories, e.g.
#
# sudo find /var -type l -print0 | perl -0e 'while(<>) { next if m,^\./tmp/,; if (! -e $_) { print; $exit=1}}; exit $exit' | xargs -0 ls -ld

use Test::More;

use strict;
use warnings;

my $debug = 1;

my @prod = qw(
  /usr/local/www/debian.bbbike.org
  /usr/local/www/bbbike
  /usr/local/www/bbbike.org
  /etc/lighttpd
  /var/cache/bbbike
  /var/lib/bbbike
  /etc/munin
);

if ( !$ENV{BBBIKE_TEST_TRAVIS} && !$ENV{BBBIKE_TEST_DOCKER} ) {
    push @prod, qw(/usr/local/www/download.bbbike.org /var/lib/bbbike/opt/share);
}

my @path = qw( . $HOME/.openstreetmap );

foreach my $dir (@prod) {
    if ( -d $dir ) {
        push( @path, $dir );
    }
    else {
        diag "ignore non-existing directory $dir\n" if $debug >= 1;
    }
}

plan tests => scalar(@path);

sub stale_symlinks {
    my $path    = shift;
    my $message = shift;

    my $prog =
        q[ find ]
      . $path
      . q[ -type l -print0 | perl -0e 'while(<>) { chomp; next if m,^\./tmp/,; if (! -e $_) { print "$_\n"; $exit=1}}; exit $exit' ];
    system($prog);
    is( $?, 0, "stale symlinks in $path" );
}

#######################################################
# main

foreach my $path (@path) {
    stale_symlinks($path);
}

__END__
