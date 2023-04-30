#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use Data::Dumper;

use Extract::Config;
use Extract::Scheduler;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $debug = 1;
plan tests => 4 + 4 + 2;

# test data
$Extract::Config::spool_dir = 'world/t/extract';

my $expected_result_confirmed = {
    'nobody@mailinator.com' => 1,
    'nobody@googlemail.com' => 14,
    'nobody@gmail.com'      => 9
};

my $expected_result_running = {
    'nobody@mailinator.com' => 1,
    'nobody@googlemail.com' => 14,
    'nobody@gmail.com'      => 9
};

###########################################################################
# test success
my $scheduler = new Extract::Scheduler( 'debug' => $debug );
my @files     = glob('world/t/extract/confirmed/[0-9a-f]*[0-9-a-f].json');

# test with explicit list of files
my $hash = $scheduler->running_users( \@files );

foreach my $key ( keys %$expected_result_confirmed ) {
    is(
        $hash->{$key},
        $expected_result_confirmed->{$key},
        "$key => $hash->{$key}"
    );
}

is(
    scalar( keys %$hash ),
    scalar( keys %$expected_result_confirmed ),
    "number of keys"
);

# test without explicit list of files
$hash = $scheduler->running_users;

foreach my $key ( keys %$expected_result_running ) {
    is(
        $hash->{$key},
        $expected_result_running->{$key},
        "$key => $hash->{$key}"
    );
}

is(
    scalar( keys %$hash ),
    scalar( keys %$expected_result_running ),
    "number of keys"
);

###########################################################################
# test failures
$hash = $scheduler->running_users( ["/foobar/x.json"] );
is( scalar( keys %$hash ), 0, "no files" );

$Extract::Config::spool_dir = '../extractXXX';
$hash                       = $scheduler->running_users();
is( scalar( keys %$hash ), 0, "no directory for glob" );

__END__
