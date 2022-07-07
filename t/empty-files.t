#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2016 Wolfram Schneider, https://bbbike.org

use Test::More;

use strict;
use warnings;

my @prod = qw(
  /usr/local/www/debian.bbbike.org
  /usr/local/www/download.bbbike.org
  /etc/lighttpd
  /var/lib/bbbike
  /etc/munin
);
my @path = qw( $HOME/.openstreetmap );

foreach my $dir (@prod) {
    push( @path, $dir ) if -d $dir;
}

sub empty_files {
    my $path    = shift;
    my $message = shift;

    my $prog =
        q[ find ]
      . $path
      . q[ -type f -size 0 -mmin +400 -print0 | perl -0e 'while(<>) { next if m,/(tmp|doc)|\.gitkeep$/,; if (-z $_) { print "$_\n"; $exit=1}}; exit $exit' ];

    system($prog);
    is( $?, 0, "empty files in $path" );
}

#######################################################
# main

foreach my $path (@path) {
    empty_files($path);
}

done_testing

__END__
