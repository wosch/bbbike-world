#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2017 Wolfram Schneider, https://bbbike.org

use Test::More;
use Data::Dumper;

use lib qw(world/lib);
use Extract::Config;
use Extract::Scheduler;

use strict;
use warnings;

my $debug = 1;
plan tests => 4 + 2;

$Extract::Config::spool_dir = '../extract';

my $expected_result = {
    'nobody@mailinator.com' => 1,
    'nobody@googlemail.com' => 14,
    'nobody@gmail.com'      => 9
};

###########################################################################
# test success
my $scheduler = new Extract::Scheduler( 'debug' => $debug );
my $hash = $scheduler->running_users;

foreach my $key ( keys %$hash ) {
    is( $hash->{$key}, $expected_result->{$key}, "$key => $hash->{$key}" );
}

is( scalar( keys %$hash ), scalar( keys %$expected_result ), "number of keys" );

###########################################################################
# test failures
$hash = $scheduler->running_users( ["/foobar/x.json"] );
is( scalar( keys %$hash ), 0, "no files" );

$Extract::Config::spool_dir = '../extractXXX';
$hash                       = $scheduler->running_users();
is( scalar( keys %$hash ), 0, "no directory for glob" );

__END__
