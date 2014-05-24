#!/usr/local/bin/perl
# Copyright (c) Aug 2013-2013 Wolfram Schneider, http://bbbike.org
#
# bbbike-org-runtime-version.t - check if we are using the right command versions
#

BEGIN { }
use Test::More;
use Data::Dumper;

use strict;
use warnings;

my $debug = 1;

my $versions = {
    'debian6' => [

        # version commands, regex to match
        [ [qw/pbzip2 --version/],  qr/ BZIP2 v1.1.[1-9] /m ],
        [ [qw/osmconvert --help/], qr/^osmconvert 0\.7T/m ],
        [ [qw/osmosis -v/],        qr/^INFO: Osmosis Version 0\.40\.1/m ],
        [ [qw/pigz --version/],    qr/^pigz (2\.1\.6|2\.2\.[4-9]|2\.3\.1)/ ],
        [ [qw/java -version/],     qr/^java version "1\.6\.0_(27|30|31)"/m ],
        [ [qw/java -version/],     qr/^OpenJDK (64-Bit )?Server VM/m ],
        [
            [qw/perltidy -v/],
            qr/^This is perltidy, (v20090616|v20101217|v20140328)/
        ],
    ]
};

# test on this OS, by default debian6/squeeze
my $os = 'debian6';

my $version = $versions->{$os};
plan tests => scalar(@$version);

######################################################################
#
foreach my $prog (@$version) {
    warn Dumper($prog) if $debug >= 2;

    my ( $command, $regex ) = @$prog;

    my $shell = join( " ", @$command );

    open( my $fh, "$shell 2>&1 |" ) or die qq{open $shell\n};
    my $data = "";
    while (<$fh>) {
        $data .= $_;
    }

    like( $data, $regex, "run '$shell' and match '$regex'" );
}

__END__
