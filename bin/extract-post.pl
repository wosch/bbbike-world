#!/usr/local/bin/perl
# Copyright (c) Sep 2012 Wolfram Schneider, http://bbbike.org
#
# extract-post.pl - extracts areas via a POST request

use HTTP::Request::Common;
use Data::Dumper;
use Encode qw/encode_utf8 decode_utf8/;
use CGI qw(escapeHTML);
use Getopt::Long;
use GIS::Distance::Lite;

use strict;
use warnings;

$ENV{'PATH'} = "/usr/local/bin:/bin:/usr/bin";

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

# timeout

my $timeout = 60;
alarm($timeout);

my $format      = 'osm.pbf';
my $city        = "";
my $email       = "";
my $coords_json = "";
my $debug       = 0;

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}          debug level, default: $debug
--city=city
--email=email\@address
--coords-json=/path/to/json
--format=format		default: $format
--timeout=timeout	default: $timeout
EOF
}

my $help;
GetOptions(
    "debug=i"       => \$debug,
    "email=s"       => \$email,
    "coords-json=s" => \$coords_json,
    "format=s"      => \$format,
    "city=s"        => \$city,
    "timeout=i"     => \$timeout,
    "help"          => \$help,
) or die usage;

die usage if $help;

die "No city name is given!\n" . &usage   if $city == "";
die "No email address given!\n" . &usage  if $email == "";
die "No format is given!\n" . &usage      if $format == "";
die "No coords file is given!\n" . &usage if $coords_json == "";

my $ua = LWP::UserAgent->new;

1;
