#!/usr/local/bin/perl
# Copyright (c) Sep 2012-2018 Wolfram Schneider, https://bbbike.org

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More;
use Data::Dumper;

use Extract::Config;
use Extract::Planet;
use Extract::Poly;
use Extract::TileSize;
use Extract::Utils;

use strict;
use warnings;

chdir("$FindBin::RealBin/../..")
  or die "Cannot find bbbike world root directory\n";

my $debug    = 1;
my $config   = new Extract::Config( 'debug' => $debug );
my $planet   = new Extract::Planet( 'debug' => $debug );
my $poly     = new Extract::Poly( 'debug' => $debug );
my $tilesize = new Extract::TileSize( 'debug' => $debug );
my $utils    = new Extract::Utils( 'debug' => $debug );

plan tests => 5;

isnt( $config,   undef, "Extract::Config" );
isnt( $planet,   undef, "Extract::Planet" );
isnt( $poly,     undef, "Extract::Poly" );
isnt( $tilesize, undef, "Extract::TileSize" );
isnt( $utils,    undef, "Extract::Utils" );

__END__
