#!/usr/local/bin/perl
# Copyright (c) 2011 Wolfram Schneider, http://bbbike.org
#
# extracts.pl - extracts areas in a batch job

use IO::File;
use IO::Dir;
use JSON;
use Data::Dumper;
use Encode;
use Email::Valid;
use Digest::MD5 qw(md5_hex);
use Net::SMTP;

use strict;
use warnings;

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

my $debug = 1;

# spool directory. Should be at least 100GB large
my $spool_dir = '/var/tmp/bbbike/extracts';

# max. area in square km
my $max_skm = 50_000;

# sent out emails as
my $email_from = 'bbbike@bbbike.org';

my $option = {
    'max_extracts'   => 50,
    'min_wait_time'  => 5 * 60,    # in seconds
    'default_format' => 'pbf',
};

my $formats = {
    'pbf'     => 'Protocolbuffer Binary Format (PBF)',
    'osm.gz'  => "OSM XML gzip'd",
    'osm.bz2' => "OSM XML bzip'd",
};

my $spool = {
    'incoming'  => "$spool_dir/incoming",
    'confirmed' => "$spool_dir/confirmed",
    'running'   => "$spool_dir/running",
    'job1'      => "$spool_dir/job1.pid",
};

# group writable file
umask(002);

######################################################################
#
#
sub get_jobs {
    my $dir = shift;

    my $d = IO::Dir->new($dir);
    if ( !defined $d ) {
        warn "Error directory $dir: $!\n";
        return ();
    }

    my @data;
    while ( defined( $_ = $d->read ) ) {
        next if !/\.json$/;
        push @data, $_;
    }
    undef $d;

    return @data;
}

# fair scheduler, take one from each customer first until 
# we reach the limit
sub parse_jobs {
    my %args = @_;

    my $dir   = $args{'dir'};
    my $files = $args{'files'};
    my $max   = $args{'max'};

    my $hash;
    foreach my $f (@$files) {
        my $file = "$dir/$f";

        my $fh = new IO::File $file, "r" or die "open $file: $!\n";
        my $json_text;
        while (<$fh>) {
            $json_text .= $_;
        }
        $fh->close;

        my $json = new JSON;
        my $json_perl = eval { $json->decode($json_text) };
        die "json $file $@" if $@;

        $json_perl->{"file"} = $f;

        # a slot for every user
        push @{ $hash->{ $json_perl->{'email'} } }, $json_perl;
    }

    # sort by user and date, oldest first
    foreach my $email ( keys %$hash ) {
        $hash->{$email} =
          [ sort { $a->{"time"} <=> $b->{"time"} } @{ $hash->{$email} } ];
    }

    # fair scheduler, take one from each customer first
    my @list;
    my $counter = $max;
    while ( $counter-- > 0 ) {
        foreach my $email ( sort keys %$hash ) {
            if ( scalar( @{ $hash->{$email} } ) ) {
                my $obj = shift @{ $hash->{$email} };
                push @list, $obj;
            }
            last if scalar(@list) >= $max;
        }
        last if scalar(@list) >= $max;
    }
    print Dumper( \@list );
}

######################################################################
# main
#
my @files = get_jobs( $spool->{'confirmed'} );

if ( !scalar(@files) ) {
    print "Nothing to do\n" if $debug;
}
else {
    parse_jobs(
        'files' => \@files,
        'dir'   => $spool->{'confirmed'},
        'max'   => 8
    );
}

