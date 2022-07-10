#!/usr/local/bin/perl
# Copyright (c) 2009-2013 Wolfram Schneider, https://bbbike.org
#
# test if all perl modules are installed
#
# sudo /usr/local/bin/cpan HTML::TagCloud

use Text::Unidecode;
use HTML::TagCloud;
use XML::Atom::SimpleFeed;
use URI;
use JSON;
use XML::Simple;
use XML::LibXML::Reader;
use Tie::IxHash;
use YAML;
use Perl::Tidy;
use BSD::Resource;

#use Date::Calc;
#use YAML::Syck;

# not used yet
#use GPS::Point;
#use Geo::Inverse;

# make first startup of bbbike.cgi 4 times faster
use Geo::Distance;

# make the search 3 times faster
use Array::Heap;

# extract.cgi
use GIS::Distance::Lite;
use Email::Valid;
use XML::LibXML::Reader;
use XML::Atom::SimpleFeed;

1;

