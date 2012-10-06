#!/usr/local/bin/perl 
# Copyright (c) 2009-2012 Wolfram Schneider, http://bbbike.org
#
# test if all perl modules are installed
#
# sudo /opt/local/bin/cpan HTML::TagCloud

use BSD::Resource;
use CDB_File;
use DB_File::Lock;
use Devel::Leak;
use Email::Valid;
use File::ReadBackwards;
use GIS::Distance::Lite;
use Geo::Google::PolylineEncoder;
use Geo::METAR;
use HTML::FormatText;
use HTML::TagCloud;
use HTML::TreeBuilder::XPath;
use Image::Info 1.31_50;
use Imager;
use JSON::XS;
use Math::MatrixReal;
use Object::Iterate;
use PDF::Create;
use PerlIO::gzip;
use String::Approx;
use Text::Table;
use Text::Unidecode;
use WWW::Mechanize::FormFiller;
use XBase;
use XML::Atom::SimpleFeed;
use XML::LibXML::Reader;
use accessors;

# extract service
use Math::Polygon;

#use Object::Realize::Later qw(becomes);

1;

