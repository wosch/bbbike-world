#!/usr/local/bin/perl
#
# Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
#
# BBBikeExtract.pm - extract config and libraries

package Extract::Utils;
use JSON;
use Data::Dumper;

require Exporter;
@EXPORT = qw();

use strict;
use warnings;

##########################
# helper functions
#

our $debug = 0;

# BBBikeExtract::new->('q'=> $q, 'option' => $option)
sub new {
    my $class = shift;
    my %args  = @_;

    my $self = {%args};

    bless $self, $class;
    $self->init;

    return $self;
}

sub init {
    my $self = shift;

    if ( defined $self->{'debug'} ) {
        $debug = $self->{'debug'};
    }
}

# scale file size in x.y MB
sub file_size_mb {
    my $self = shift;
    my $size = shift;

    foreach my $scale ( 10, 100, 1000, 10_000 ) {
        my $result = int( $scale * $size / 1024 / 1024 ) / $scale;
        return $result if $result > 0;
    }

    return "0.0";
}

sub parse_json_file {
    my $self      = shift;
    my $file      = shift;
    my $non_fatal = shift;

    warn "Open file '$file'\n" if $debug >= 2;

    my $fh = new IO::File $file, "r" or die "open '$file': $!\n";
    binmode $fh, ":utf8";

    my $json_text;
    while (<$fh>) {
        $json_text .= $_;
    }
    $fh->close;

    my $json = new JSON;
    my $json_perl = eval { $json->decode($json_text) };
    if ($@) {
        warn "parse json file '$file' $@\n";
        exit(1) if $non_fatal;
    }

    warn Dumper($json_perl) if $debug >= 3;
    return $json_perl;
}

# random sort of filenames
sub random_filename_sort {
    my $self = shift;
    return $self->random_sort(@_);
}

sub random_sort {
    my $self  = shift;
    my @files = @_;

    my %hash = map { $_ => rand() } @files;

    return sort { $hash{$a} <=> $hash{$b} } keys %hash;
}

1;

__DATA__;
