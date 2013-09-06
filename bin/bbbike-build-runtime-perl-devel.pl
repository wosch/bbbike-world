#!/usr/local/bin/perl 
# Copyright (c) 2009-2013 Wolfram Schneider, http://bbbike.org
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
use String::Approx;
use Text::Table;
use Text::Unidecode;
use WWW::Mechanize::FormFiller;
use XBase;
use XML::Atom::SimpleFeed;
use XML::LibXML::Reader;
use accessors;
use YAML::XS;
use IPC::Run;
use Archive::Zip;
use Cairo;
use Class::Accessor;
use DBI;
use Date::Calc;
use GD;
use GD::SVG;
use Image::ExifTool;
use Image::Magick;
use Imager::File::JPEG;
use Imager::File::PNG;
use SVG;
use Statistics::Descriptive;
#use Strassen::InlineDist;
#use StrassenNetz::CNetFile;
use Template;
use XML::Twig;

#use PerlIO::gzip;

# extract service
use Math::Polygon;

#use Object::Realize::Later qw(becomes);

1;

