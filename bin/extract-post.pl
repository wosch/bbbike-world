#!/usr/local/bin/perl
# Copyright (c) Sep 2012 Wolfram Schneider, http://bbbike.org
#
# extract-post.pl - extracts areas via a POST request

use HTTP::Request::Common;
use Data::Dumper;
use Encode qw/encode_utf8 decode_utf8/;
use CGI qw(escapeHTML);
use JSON;
use Getopt::Long;
use LWP::UserAgent;

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
my $coords_perl = "";
my $debug       = 0;
my $url         = 'http://localhost/cgi/extract.cgi';

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}          debug level, default: $debug
--city=city
--email=email\@address
--coords-json=/path/to/data.json
--coords-perl=/path/to/data.pl
--format=format		default: $format
--timeout=timeout	default: $timeout
--url=url		default: $url
EOF
}

# read a json (or perl) array from file into perl scalar
sub get_json_from_file {
    my $file = shift;

    local $/;
    open( my $fh, '<', $file ) or die "open $file: $!\n";

    my $perl = decode_json(<$fh>);

    return $perl;
}

sub get_perl_from_file {
    my $file = shift;

    my $perl = require $file;
    return $perl;
}

# convert perl array to coords=<....> parameter
sub perl2coords {
    my $list = shift;

    my $data = "";
    foreach my $p (@$list) {
        $data .= '|' if $data;
        $data .= "$p->[0],$p->[1]";
    }

    warn Dumper($list) if $debug >= 2;
    warn "$data\n" if $debug >= 2;

    return $data;
}

my $help;
GetOptions(
    "debug=i"       => \$debug,
    "email=s"       => \$email,
    "coords-json=s" => \$coords_json,
    "coords-perl=s" => \$coords_perl,
    "format=s"      => \$format,
    "city=s"        => \$city,
    "url=s"         => \$url,
    "timeout=i"     => \$timeout,
    "help"          => \$help,
) or die usage;

die usage if $help;

die "No city name is given!\n" . &usage  if $city   eq "";
die "No email address given!\n" . &usage if $email  eq "";
die "No format is given!\n" . &usage     if $format eq "";
die "No coords file is given!\n" . &usage
  if $coords_json eq "" && $coords_perl eq "";

my $coords = perl2coords(
    $coords_json
    ? get_json_from_file($coords_json)
    : get_perl_from_file($coords_perl)
);
my $ua = LWP::UserAgent->new;

my $response = $ua->request(
    POST $url,
    [
        'submit' => 'extract',
        'city'   => $city,
        'format' => $format,
        'email'  => $email,
        'coords' => $coords
    ]
);

if ( $response->is_success ) {
    if ( $response->decoded_content =~ / class="error">(.*?)</ ) {
        die "Got an error: $1\n";
    }
}
else {
    die $response->status_line;
}

1;
