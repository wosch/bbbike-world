#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2013 Wolfram Schneider, http://bbbike.org
#
# extract-post.pl - extracts areas via a POST request

use HTTP::Request::Common;
use Data::Dumper;
use Encode qw/encode_utf8 decode_utf8/;
use CGI qw(escapeHTML);
use JSON;
use Getopt::Long;
use LWP::UserAgent;
use File::Temp;

use strict;
use warnings;

$ENV{'PATH'} = "/usr/local/bin:/bin:/usr/bin:/opt/local/bin";

binmode \*STDOUT, ":utf8";
binmode \*STDERR, ":utf8";

# timeout

my $timeout = 60;
alarm($timeout);

my $format       = 'osm.pbf';
my $city         = "";
my $email        = "";
my $coords_json  = "";
my $extract_file = "";
my $coords_perl  = "";
my $coords_poly  = "";
my $debug        = 0;
my $url          = 'http://localhost/cgi/extract.cgi';

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug={0..2}          debug level, default: $debug
--city=city
--email=email\@address
--coords-json=/path/to/data.json
--coords-perl=/path/to/data.pl
--coords-poly=/path/to/data.poly
--extract-file=/path/to/extract.json
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

# read a poly file into perl scalar
sub get_poly_from_file {
    my $file = shift;

    open( my $fh, '<', $file ) or die "open $file: $!\n";
    my @data;

    while (<$fh>) {
        next if !/^\s+/;
        chomp;

        my ( $lng, $lat ) = split;
        push @data, [ $lng, $lat ];
    }

    return \@data;
}

sub get_perl_from_file {
    my $file = shift;

    my $perl = require $file;
    return $perl;
}

sub get_extract_from_file {
    my $file = shift;
    my $args = shift;

    my $obj = get_json_from_file($file);

    $args->{'city'}   = $obj->{'city'}   if $obj->{'city'};
    $args->{'format'} = $obj->{'format'} if $obj->{'format'};

    # backward compatible
    $args->{'format'} =~ s/^osm\.(navit.zip|shp.zip|obf.zip)/$1/;

    my $coords = $obj->{'coords'};
    
    # backward compatible
    $coords = [] if ref $coords ne 'ARRAY';

    if (   !defined $coords
        || $coords eq ""
        || ( ref $coords eq 'ARRAY' && scalar(@$coords) == 0 ) )
    {
        if (   $obj->{ne_lat} ne ""
            && $obj->{sw_lat} ne ""
            && $obj->{sw_lng} ne ""
            && $obj->{ne_lng} )
        {
            $coords = [
                [ $obj->{sw_lng}, $obj->{sw_lat} ],
                [ $obj->{ne_lng}, $obj->{sw_lat} ],
                [ $obj->{ne_lng}, $obj->{ne_lat} ],
                [ $obj->{sw_lng}, $obj->{ne_lat} ]
            ];
        }
    }

    warn Dumper($obj) if $debug >= 2;
    warn Dumper( $args, $coords ) if $debug >= 2;

    return (
        perl2coords($coords), $args->{'city'},
        $args->{'format'},    $args->{'email'}
    );
}

# convert perl array to coords=<....> parameter
sub perl2coords {
    my $list = shift;

    my $data = "";
    foreach my $p (@$list) {
        $data .= '|' if $data;
        $data .= "$p->[0],$p->[1]";
    }

    warn "perl2coords: " . Dumper($list) if $debug >= 2;
    warn "$data\n" if $debug >= 2;

    return $data;
}

################################################################################
#
# main
#
my $help;
GetOptions(
    "debug=i"        => \$debug,
    "email=s"        => \$email,
    "coords-json=s"  => \$coords_json,
    "extract-file=s" => \$extract_file,
    "coords-perl=s"  => \$coords_perl,
    "coords-poly=s"  => \$coords_poly,
    "format=s"       => \$format,
    "city=s"         => \$city,
    "url=s"          => \$url,
    "timeout=i"      => \$timeout,
    "help"           => \$help,
) or die usage;

die usage if $help;

my $coords;
if ( $extract_file ne "" ) {
    ( $coords, $city, $format, $email ) =
      &get_extract_from_file( $extract_file,
        { 'city' => $city, 'email' => $email, 'format' => $format } );
}
else {
    $coords = perl2coords(
          $coords_json ? get_json_from_file($coords_json)
        : $coords_perl ? get_perl_from_file($coords_perl)
        : get_poly_from_file($coords_poly)
    );
}

die "No city name is given!\n" . &usage  if $city   eq "";
die "No email address given!\n" . &usage if $email  eq "";
die "No format is given!\n" . &usage     if $format eq "";
die "No coords file is given!\n" . &usage
  if $coords_json eq ""
      && $coords_perl  eq ""
      && $coords_poly  eq ""
      && $extract_file eq "";

die "No coordinates found in input file!\n" if $coords eq "";

my $ua        = LWP::UserAgent->new;
my $url_param = {
    'submit' => 'extract',
    'city'   => $city,
    'format' => $format,
    'email'  => $email,
    'coords' => $coords,
    'as'     => 1,
};

warn "$url @{[ Dumper($url_param) ]}\n" if $debug >= 1;
my $response = $ua->post( $url, $url_param );

if ( $response->is_success ) {
    if ( $response->decoded_content =~ / class="error">(.*?)</ ) {
        my ($fh) = File::Temp->new( UNLINK => 0, SUFFIX => '.html' );
        print $fh $response->decoded_content;
        warn "Got an error: $1\nSee @{[ $fh->filename ]}\n";
        system( "lynx", "-nolist", "-dump", $fh->filename );
        exit 1;
    }
}
else {
    die $response->status_line;
}

1;
