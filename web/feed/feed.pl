#!/usr/local/bin/perl
# Copyright (c) 2010-2018 Wolfram Schneider, https://bbbike.org
#
# feed.pl - generate RSS/Atom feed

use XML::Atom::SimpleFeed;
use File::stat;

use strict;
use warnings;

my $homepage = $ENV{'BBBIKE_HOMEPAGE'} || 'https://www.bbbike.org';

sub self_mod_time {
    my $file = $0;
    my $git  = 1;

    if ($git) {
        my $mtime = qx(git log feed.pl | head -3 | tail -1);
        $mtime =~ s/^Date:\s*//;
        return $mtime;
    }

    else {

        my $st = stat($file) or die "stat $file: $!\n";
        return POSIX::strftime( XML::Atom::SimpleFeed::W3C_DATETIME,
            gmtime( $st->mtime ) );
    }
}

my $feed = XML::Atom::SimpleFeed->new(
    title => 'BBBike@World - a Cycle Route Planner',
    link  => $homepage,
    link  => { rel => 'self', href => $homepage . '/feed/bbbike-world.xml' },
    icon  => $homepage . '/images/srtbike.ico',

    updated => &self_mod_time(),      #'2011-04-09T18:30:03Z',
    author  => 'Wolfram Schneider',
    subtitle =>
'BBBike is a route planner for cyclists in Berlin. It is now ported to other cities around the world - thanks to the OpenStreetMap project!',
    id => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af7',
);

######################################################################
#
# TODO
# - larger area for most cities, up top 30 km radius the centr of the city
#

$feed->add_entry(
    title =>
      qq{The BBBike Map Compare service supports now historic maps of Berlin},
    id      => 'a41861d665e7302109a74327df5cbe5d',
    content => {
        type => 'html',
        content =>
qq{<a href="https://mc.bbbike.org/mc/?profile=historicmaps-berlin-1698-1871">1698-1871</a>
<a href="https://mc.bbbike.org/mc/?profile=historicmaps-berlin-1874-1900">1874-1900</a>
<a href="https://mc.bbbike.org/mc/?profile=historicmaps-berlin-1903-1913">1903-1913</a>
<a href="https://mc.bbbike.org/mc/?profile=historicmaps-berlin-1914-1928">1914-1928</a>},
    },
    updated  => '2019-04-14T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New OSM export format SQLite},
    id      => '396b20cf70a9aec7c349db9fcf9723a3',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports SQLite format},
    },
    updated  => '2018-05-20T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New OSM export format GeoJSON},
    id      => '396b20cf70aaaec7c349db9fcf9723a3',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports GeoJSON format},
    },
    updated  => '2018-05-13T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Perl/Tk extracts for the BBBike App},
    id      => '396b20cf70aaaec7c379db9fcf9723a3',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports the Perl/Tk App},
    },
    updated  => '2017-09-29T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New Garmin style OpenTopoMap},
    id      => '5f5b1fc9a70a140420758b84427c7ea7',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports Garmin OpenTopoMap style},
    },
    updated  => '2017-04-15T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New Garmin style OpenSeaMap},
    id      => '5f5b1fc9a70a140420758b84427c8ea7',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports Garmin OpenSeaMap style},
    },
    updated  => '2016-10-15T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{More us-ascii Garmin styles},
    id      => 'fa7db982ca948a37feadd25d35c95955',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports more Garmin styles in us-ascii for devices without unicode support, or broken DRM},
    },
    updated  => '2016-09-17T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New us-ascii Garmin styles},
    id      => 'fb7db982ca948a37feadd25d35c95955',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports Garmin styles in us-ascii for devices without unicode support, or broken DRM},
    },
    updated  => '2016-03-26T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New Garmin style Openfietsmap Lite},
    id      => '6f5b1fc9a70a146420758b84427c8ea7',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports Garmin Openfietsmap Lite style},
    },
    updated  => '2016-03-19T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New Garmin style "Onroad" for older devices with less space - usually 1/10 the size of Garmin OSM},
    id      => '5f5b1fc9a70a146420758b84427c8ea7',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports Garmin Onroad style for older devices with less space},
    },
    updated  => '2016-03-19T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      qq{The extract service supports now MAPSE.ME format for Android and iOS},
    id      => '5f5b1fc9a70a146420758b84227c8ea7',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now MAPSE.ME format for Android and iOS},
    },
    updated  => '2015-11-24T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      qq{Map Compare now supports up to 140 maps: https://mc.bbbike.org/mc/},
    id      => '8f26db14e49f2e3a1c6e3e46f6fe5d83',
    content => {
        type => 'html',
        content =>
qq{Map Compare now supports up to 140 maps: <a href="https://mc.bbbike.org/mc/">bbbike.org/mc</a>},
    },
    updated  => '2015-10-06T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{The extract service supports now SVG format and PNG images},
    id      => '5f5b1fc9a70af4642e758b84227c8ea7',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now SVG format and PNG images},
    },
    updated  => '2015-09-13T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The extract service is now 5 times faster. It takes between 2-7 minutes to extract an area from planet.osm},
    id      => '5f5b1fc9a70af4642e758b84227c8ea6',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">extract service</a> is now 5 times faster. It takes between 2-7 minutes to extract an area from planet.osm},
    },
    updated  => '2015-05-24T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      qq{Map Compare now supports up to 108 maps: https://mc.bbbike.org/mc/},
    id      => '51d474fb21860b0629bfe8467ee42c0d',
    content => {
        type => 'html',
        content =>
qq{Map Compare now supports up to 108 maps: <a href="https://mc.bbbike.org/mc/">bbbike.org/mc</a>},
    },
    updated  => '2014-12-06T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{BBBike Windows Phone app},
    id      => 'dda2b9aa0307ba9a55d2dd15a93dcbd2',
    content => {
        type => 'html',
        content =>
qq{A free <a href="https://www.windowsphone.com/s?appid=6cc2f571-7c0e-414c-9e71-806162601d7a">BBBike Windows Phone app</a>
	is availble in the Windows Phone store. The city Berlin use the original BBBike data, the other cities are OSM based.}
    },
    updated  => '2014-08-22T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{<a href="https://www.bbbike.org/">BBBike cycle route searches</a> are now 2-3 times faster},
    id      => 'd41d8cd98f00b204e9800998ecf8437e',
    content => {
        type => 'html',
        content =>
qq{<a href="https://www.bbbike.org/">BBBike cycle route searches</a> are now 2-3 times faster}
    },
    updated  => '2014-07-22T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now libosmium OPL format},
    id      => 'd41d8cd98f00b204e9800998ecf8437e',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now libosmium OPL format},
    },
    updated  => '2014-05-27T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now Contours (SRTM) extracts for PBF, Garmin, and Osmand},
    id      => '21de8970bd81fb04b751c1935e023e0d',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now SRTM extracts for PBF, Garmin, and Osmand},
    },
    updated  => '2014-04-15T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now CSV format},
    id      => 'd41d8cd98f00b204e9800998ecf8427e',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now CSV format},
    },
    updated  => '2013-08-17T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{GPSies blog article (German): Easy way to generate maps for Garmin GPS and Android Locus app <a href="http://blog.gpsies.com/article/187/karten-aus-openstreetmap-fuer-garmin-outdoor-gps-erstellen">http://blog.gpsies.com/article/187/karten-aus-openstreetmap-fuer-garmin-outdoor-gps-erstellen</a>},
    id      => 'd6f59d1bb8315958eb25b197de28d24d',
    content => {
        type => 'html',
        content =>
qq{GPSies blog article (German): Easy way to generate maps for Garmin GPS and Android Locus app <a href="http://blog.gpsies.com/article/187/karten-aus-openstreetmap-fuer-garmin-outdoor-gps-erstellen">http://blog.gpsies.com/article/187/karten-aus-openstreetmap-fuer-garmin-outdoor-gps-erstellen</a>},
    },
    updated  => '2013-05-15T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The new iPhone app for BBBike is available. It's free, try it <a href="https://itunes.apple.com/de/app/bbybike-made-in-berlin-for/id639384862?l=en&mt=8">out</a>!},
    id      => 'd6f59d1bb8315958eb25b197de28d25d',
    content => {
        type => 'html',
        content =>
qq{The new iPhone app for BBBike is available. It's free, try it <a href="https://itunes.apple.com/de/app/bbybike-made-in-berlin-for/id639384862?l=en&mt=8">out</a>!},
    },
    updated  => '2013-04-30T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{<a href="https://extract.bbbike.org/?lang=ru">BBBike extract service</a> now in Russian.},
    id      => 'd6f59d1bb8315958eb25b197de28d25c',
    content => {
        type => 'html',
        content =>
qq{<a href="https://extract.bbbike.org/?lang=ru">BBBike extract service</a> now in Russian.},
    },
    updated  => '2013-03-31T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{<a href="https://extract.bbbike.org/?lang=fr">BBBike extract service</a> now in French.},
    id      => 'd6f59d1bb8315958eb25b187de28d25c',
    content => {
        type => 'html',
        content =>
qq{<a href="https://extract.bbbike.org/?lang=fr">BBBike extract service</a> now in French.},
    },
    updated  => '2013-03-26T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{<a href="https://extract.bbbike.org/?lang=es">BBBike extract service</a> now in Spanish.},
    id      => 'd6f59d1bb8315958eb25b187de28d25d',
    content => {
        type => 'html',
        content =>
qq{<a href="https://extract.bbbike.org/?lang=es">BBBike extract service</a> now in Spanish.},
    },
    updated  => '2013-03-26T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Den <a href="https://extract.bbbike.org/?lang=de">BBBike extract service</a> gibt es jetzt auch auf deutsch.},
    id      => 'd6f59d1bb8315958eb25b187de28d25b',
    content => {
        type => 'html',
        content =>
qq{Den <a href="https://extract.bbbike.org/?lang=de">BBBike extract service</a> gibt es jetzt auch auf deutsch.},
    },
    updated  => '2013-03-17T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now mapsforge format},
    id      => 'd6f59d1bb8315958eb25b187de28d25b',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now mapsforge format for Android devices},
    },
    updated  => '2013-02-10T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Added new cities',
    id    => '9db3b2d0cfc74b943a07cb11e553efc5',

    content => {
        type    => 'text',
        content => qq{New city: La Plata},
    },

    updated  => '2012-11-17T12:31:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now .o5m format},
    id      => 'd6f59d1bb8315958eb25b187de28d25a',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now .o5m format},
    },
    updated  => '2012-11-17T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now polygons},
    id      => '51d474fb21861b0629bfe8467ee42c0f',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now polygons},
    },
    updated  => '2012-10-28T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now the Navit format},
    id      => '51d474fb21860b0629bfe8467ee42c0f',
    content => {
        type => 'html',
        content =>
qq{The <a href="https://extract.bbbike.org/">BBBike extract service</a> supports now the Navit format},
    },
    updated  => '2012-10-18T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{A new <a href="https://bbbike.jochen-pfeiffer.com/en/">BBBike iPhone app</a> is availble in the iTune store.},
    id      => '51d474fb21860b0629bfe8467ee42c0d',
    content => {
        type => 'html',
        content =>
qq{A new <a href="http://bbbike.jochen-pfeiffer.com/en/">BBBike iPhone app</a> is availble in the iTune store. The city Berlin use the original BBBike data, the other cities are OSM based.},
    },
    updated  => '2012-09-04T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Map Compare with new maps: Nokia Map, Terrain, Satellite, Hybrid, Public Transit, Traffic. Map Compare now supports up to 52 maps: https://mc.bbbike.org/mc/},
    id      => '51d474fb21860b0629bfe8467ee42c0c',
    content => {
        type => 'text',
        content =>
qq{Map Compare with new maps: Nokia Map, Terrain, Satellite, Hybrid, Public Transit, Traffic. Map Compare now supports up to 52 maps: https://mc.bbbike.org/mc/},
    },
    updated  => '2012-08-06T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: BBBike extract service with Osmand map format #osm #android},
    id      => '51d474fb21860b0629bfe8467ee42c0b',
    content => {
        type => 'text',
        content =>
qq{New feature: BBBike extract service with Osmand map format #osm #android},
    },
    updated  => '2012-07-23T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: Map Compare supports up to 32 maps on the screen and a fullscreen mode: https://mc.bbbike.org/mc/},
    id      => '51d474fb21860b0629bfe8467ee42c0b',
    content => {
        type => 'text',
        content =>
qq{Map Compare supports up to 32 maps on the screen and a fullscreen mode: https://mc.bbbike.org/mc/},
    },
    updated  => '2012-06-08T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: BBBike extract service with shapefile map format #osm #esri #gis},
    id      => '51d474fb21860b0629bfe8467ee42c0a',
    content => {
        type => 'text',
        content =>
          qq{New feature: BBBike extract service with OSM Shape map format},
    },
    updated  => '2012-06-08T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{A new BBBike Android app (Berlin only, original data) is available in the android market: https://play.google.com/store/search?q=bbbike},
    id      => 'ceb834ea55261da7259fd57c8760d81f',
    content => {
        type => 'text',
        content =>
qq{A new BBBike Android app (Berlin only, original data) is available in the android market: https://play.google.com/store/search?q=bbbike},
    },
    updated  => '2012-22-20T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: BBBike extract service with Garmin OSM and Garmin cycle map format},
    id      => 'ceb834ea55261da7259fd57c8760d80f',
    content => {
        type => 'text',
        content =>
qq{New feature: BBBike extract service with Garmin OSM and Garmin cycle map format},
    },
    updated  => '2012-05-20T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added new cities: LaPaz, Cusco, and Sucre},
    id      => 'd94a133044bb2da6cc7177e80e24c751',
    content => {
        type    => 'text',
        content => qq{Added new cities: LaPaz, Cusco, and Sucre},
    },
    updated  => '2012-05-13T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added Toner and Watercolor maps for https://bbbike.org},
    id      => 'd94a133044bb2da6cc7177e80e24c750',
    content => {
        type    => 'text',
        content => qq{Added Toner and Watercolor maps for https://bbbike.org},
    },
    updated  => '2012-04-10T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => qq{New feature: start a route search with right click on the map},
    id    => '59f077289e137c87be26a4b5f22427d7',
    content => {
        type => 'text',
        content =>
          qq{New feature: start search a route with right click on the map},
    },
    updated  => '2012-04-09T13:31:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      qq{New feature: move start or destination pointers from a street marker},
    id      => '59f077289e137c87be26a4b5f22427d6',
    content => {
        type => 'text',
        content =>
qq{New feature: move start or destination pointers from a street marker},
    },
    updated  => '2012-04-08T13:31:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Improve HTML layout, use all available space for map},
    id      => '59f077289e137c87be26a4b5f22427d5',
    content => {
        type    => 'text',
        content => qq{Improve HTML layout, use all available space for map},
    },
    updated  => '2012-04-08T13:31:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added new overlay map: Google Panoramio photos},
    id      => '59f077289e137c87be26a4b5f22427d4',
    content => {
        type    => 'text',
        content => qq{Added new overlay map: Google Panoramio photos},
    },
    updated  => '2012-04-08T13:31:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added new overlay map: Google Weather},
    id      => '59f077289e137c87be26a4b5f22427d3',
    content => {
        type    => 'text',
        content => qq{Added new overlay map: Google Weather},
    },
    updated  => '2012-04-08T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New feature: replay a route on the map},
    id      => '59f077289e137c87be26a4b5f22427d2',
    content => {
        type    => 'text',
        content => qq{New feature: replay a route on the map},
    },
    updated  => '2012-03-26T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added new overlay maps: Velo and Max Speed},
    id      => '59f077289e137c87be26a4b5f22427d1',
    content => {
        type    => 'text',
        content => qq{Added new overlay maps: Velo and Max Speed},
    },
    updated  => '2012-03-12T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added new map Apple},
    id      => '59f077289e137c87be26a4b5f22427d0',
    content => {
        type    => 'text',
        content => qq{Added new map Apple},
    },
    updated  => '2012-03-10T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added new map MapBox},
    id      => '89ed7e9fc6f6107c641d8fecf15f50c9',
    content => {
        type    => 'text',
        content => qq{Added new map MapBox},
    },
    updated  => '2012-03-04T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New service: extract service for OSM data},
    id      => 'ceb834ea55261da7259fd57c8760d80e',
    content => {
        type => 'text',
        content =>
qq{New extract service for OSM data, select your individual area up to 400km x 600km large, https://extract.bbbike.org},
    },
    updated  => '2012-03-01T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New feature: new maps Esri and Esri Topo},
    id      => 'd002aa4014948d154e57eacf0c662a0f',
    content => {
        type    => 'text',
        content => qq{New feature: new maps Esri and Esri Topo},
    },
    updated  => '2012-02-19T13:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New feature: new maps MapQuest and MapQuest Sat},
    id      => 'd002aa4014948d154e57eacf0c662a0e',
    content => {
        type    => 'text',
        content => qq{New feature: new maps MapQuest and MapQuest Sat},
    },
    updated  => '2012-02-19T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New feature: a Land Shading overlay layer (Hills)},
    id      => '27ee6bd90e6f17590f0c1c045cda3722',
    content => {
        type    => 'text',
        content => qq{New feature: a Land Shading overlay layer (Hills)},
    },
    updated  => '2012-02-18T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      qq{Added OpenCycleMaps Landscape and Transport for https://bbbike.org},
    id      => '4953cbf8a82f394f88ec2e49898c5e0e',
    content => {
        type => 'text',
        content =>
qq{Added OpenCycleMaps Landscape and Transport for https://bbbike.org},
    },
    updated  => '2012-02-17T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Added new cities',
    id    => '8b4c4c5b6f1175986ef6cc55bcd0bd41',

    content => {
        type    => 'text',
        content => qq{New city: Wuerzburg},
    },

    updated  => '2011-12-12T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: a smoothness layer for streets in Berlin (excellent, good, cobblestones, horrible) },
    id      => '75c151c463e1f249498a6571c8d05ccc',
    content => {
        type => 'text',
        content =>
qq{New feature: a smoothness layer for streets in Berlin (excellent, good, cobblestones, horrible) },
    },
    updated  => '2011-11-08T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: support search for addresses with house numbers and zip code},
    id      => '171f3263a6e73b3bf6e3256c6cb094f4',
    content => {
        type => 'text',
        content =>
          qq{New: support search for addresses with house numbers and zip code},
    },
    updated  => '2011-09-30T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New feature: allow to set start and destination of a cycle route with markers on the map},
    id      => '171f3263a6e73b3bf6e3256c6cb094f3',
    content => {
        type => 'text',
        content =>
qq{New feature: allow to set start and destination of a cycle route with markers on the map},
    },
    updated  => '2011-09-29T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Emden/Ostfriesland},
    id      => '171f3263a6e73b3bf6e3256c6cb094f6',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Emden/Ostfriesland: https://www.bbbike.org/Emden},
    },
    updated  => '2011-09-11T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Bremerhaven},
    id      => '171f3263a6e73b3bf6e3256c6cb094f7',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Bremerhaven: https://www.bbbike.org/Bremerhaven},
    },
    updated  => '2011-09-11T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Heilbronn},
    id      => '7b2006882ab330199ea21240ce787723',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Heilbronn: https://www.bbbike.org/Heilbronn},
    },
    updated  => '2011-09-11T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Madrid},
    id      => 'a440093ff2ecb6ffe9e5646b49a1d501',
    content => {
        type => 'text',
        content =>
          qq{New: cycle routing for Madrid: https://www.bbbike.org/Madrid},
    },
    updated  => '2011-09-08T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Alexandria},
    id      => '1ac05653bda68ca1346b5cbf083f3c88',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Alexandria: https://www.bbbike.org/Alexandria},
    },
    updated  => '2011-09-04T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{https://BBBike.org moved to a faster machine. Have fun!},
    id      => '1ac05653bda68ca1346b5cbf083f3c87',
    content => {
        type    => 'text',
        content => qq{https://BBBike.org moved to a faster machine. Have fun!},
    },
    updated  => '2011-08-03T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Memphis},
    id      => '1f1405ff29bce1549e0a7c0269d15467',
    content => {
        type => 'text',
        content =>
          qq{New: cycle routing for Memphis: https://www.bbbike.org/Memphis},
    },
    updated  => '2011-06-07T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Allow to move the map left or right.},
    id      => 'af55477bc54143ea90ee66ab34b850a8',
    content => {
        type    => 'text',
        content => qq{Allow to move the map left or right.}
    },
    updated  => '2011-05-22T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Support cycle route search with a via point.},
    id      => 'af55477bc54143ea90ee66ab34b850a9',
    content => {
        type    => 'text',
        content => qq{Support cycle route search with a via point.}
    },
    updated  => '2011-05-22T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Support route search for Point of Interest (POI), for train stations, schools, buildings, restaurants, sights etc.},
    id      => '9511e253bd8ac0da0fb7ab4c7a5f1ac2',
    content => {
        type => 'text',
        content =>
qq{Support route search for Point of Interest (POI), for train stations, schools, buildings, restaurants, sights etc.}
    },
    updated  => '2011-05-17T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Added a Map Slide Show for all 7 #osm maps and 11 non-osm maps on https://bbbike.org},
    id      => '17fe6ae451ab0eb00b25f59a0cb7b75c',
    content => {
        type    => 'text',
        content => qq{Added map slide show for https://bbbike.org},
    },
    updated  => '2011-05-02T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added Full Screen View for https://bbbike.org},
    id      => '15c559e7c35a7dac75a141c92877dabd',
    content => {
        type    => 'text',
        content => qq{Added Added Full Screen View for https://bbbike.org},
    },
    updated  => '2011-05-01T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added black/white Mapnik map for https://bbbike.org},
    id      => '8180c31f8c34e75058495ff6a1bf7f8d',
    content => {
        type    => 'text',
        content => qq{Added black/white Mapnik map for https://bbbike.org},
    },
    updated  => '2011-05-01T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Added Yahoo and Bing maps (satellite, hybrid, map) for https://bbbike.org},
    id      => '9de8ff38b08a07a69968512b8def69ec',
    content => {
        type => 'text',
        content =>
qq{Added Yahoo and Bing maps (satellite, hybrid, map) for https://bbbike.org}
    },
    updated  => '2011-04-24T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{Added OpenStreetMaps map Hike&Bike for https://bbbike.org},
    id      => '112d59fb9de68297123558b6c7d278e5',
    content => {
        type => 'text',
        content =>
qq{New: suport google maps v3 layers bicycling, traffic and panoramio},
    },
    updated  => '2011-04-23T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Added OpenStreetMaps maps public transport and German Mapnik for European cities},
    id      => '2eb7271b2f3fbc1056ebe01e06e69676',
    content => {
        type => 'text',
        content =>
qq{New: suport google maps v3 layers bicycling, traffic and panoramio},
    },
    updated  => '2011-04-23T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{Added google maps v3 layers bicycling, traffic and panoramio for https://bbbike.org},
    id      => 'f66f22b31bb6aa46ee0b71f25c31a694',
    content => {
        type => 'text',
        content =>
qq{New: suport google maps v3 layers bicycling, traffic and panoramio},
    },
    updated  => '2011-04-23T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Kaiserslautern and Salzburg},
    id      => 'a2390777c2e2c60c01c94121836458aa',
    content => {
        type    => 'text',
        content => qq{New: cycle routing for Kaiserslautern and Salzburg},
    },
    updated  => '2011-04-17T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Gera and Dessau},
    id      => 'c9fca418ccf44c117367127fd236a669',
    content => {
        type    => 'text',
        content => qq{New: cycle routing for Gera and Dessau},
    },
    updated  => '2011-04-10T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Hamm and Moenchengladbach},
    id      => 'ec119bc2cf68e262a6c0deb36a30f5c3',
    content => {
        type    => 'text',
        content => qq{New: cycle routing for Hamm and Moenchengladbach},
    },
    updated  => '2011-04-07T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Waterloo and Kitchener, Ontario},
    id      => '1f1405ff29bce1549e0a7c0269d15466',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Waterloo and Kitchener, Ontario: https://www.bbbike.org/Waterloo},
    },
    updated  => '2011-04-02T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => qq{New: cycle routing for Luxemburg, Lake Balaton, Cork, Lausanne},
    id    => '9be2454e1d61e6abadea574f1779c74d',
    content => {
        type => 'text',
        content =>
          qq{New: cycle routing for Luxemburg, Lake Balaton, Cork, Lausanne},
    },
    updated  => '2011-03-24T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New: cycle routing for Braunschweig/Wolfsburg, Wuppertal, Usedom/Greifswald,, Schwerin/Wismar, Flensburg, Koblenz, Saarbruecken},
    id      => 'bd199616e9f56b41d8566895b21d8f9f',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Braunschweig/Wolfsburg, Wuppertal, Usedom/Greifswald,, Schwerin/Wismar, Flensburg, Koblenz, Saarbruecken},
    },
    updated  => '2011-03-24T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New: cycle routing for Dallas, Stockton, Portland ME, Huntsville, New Orleans},
    id      => 'a7a750d08f9009fa0695d78167894381',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Dallas, Stockton, Portland ME, Huntsville AL, New Orleans},
    },
    updated  => '2011-03-21T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Lodz, Brno, Ostrava, Calgary},
    id      => 'cd703c8c5c464d05509931f62f578a0c',
    content => {
        type    => 'text',
        content => qq{New: cycle routing for Lodz, Brno, Ostrava, Calgary},
    },
    updated  => '2011-03-21T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New: cycle routing for Lyon, Toulouse, Bordeaux, Montpellier, Clermont-Ferrand, Corsica},
    id      => '604c4a5ac89c1af7e7d7b6f0f7ecf4d5',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Lyon, Toulouse, Bordeaux, Montpellier, Clermont-Ferrand, Corsica},
    },
    updated  => '2011-03-20T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => qq{New: cycle routing for Antwerpen, Bruegge, Gent},
    id      => 'e53b734df1d017e695a60d9f9a91c915',
    content => {
        type    => 'text',
        content => qq{New: cycle routing for Antwerpen, Bruegge, Gent},
    },
    updated  => '2011-03-19T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
qq{New: cycle routing for 's-Hertogenbosch, Arnhem, Eindhoven, Maastricht, Tilburg, Utrecht},
    id      => '579e68d390c03319d8445fc43966a6cb',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for 's-Hertogenbosch, Arnhem, Eindhoven, Maastricht, Tilburg, Utrecht},
    },
    updated  => '2011-03-19T12:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title =>
'New: cycle routing for Augsburg, Halle (Saale), Konstanz, Osnabrueck, Paderborn, Regensburg, Ulm',
    id      => '579e68d390c03319d8445fc43966a6cc',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Augsburg, Halle (Saale), Konstanz, Osnabrück, Paderbor, Regensburg, Ulm},
    },
    updated  => '2011-03-19T12:30:04Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for Malmoe and Gothenburg',
    id      => 'c8149d780c2dff3451db938c7b282264',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Malmoe and Gothenburg: https://www.bbbike.org/Malmoe https://www.bbbike.org/Goetheburg}
    },
    updated  => '2011-03-08T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for Stuttgart',
    id      => '86ae45c86b9d90f50feed5c321dd61a5',
    content => {
        type => 'text',
        content =>
          qq{New: cycle routing for Stuttgart: https://www.bbbike.org/Stuttgart}
    },
    updated  => '2011-03-07T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for Berkeley',
    id      => 'df1301be6fe83a6731d7840ee3408efa',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Berkeley, East Bay (San Francisco Bay Area): https://www.bbbike.org/Berkeley}
    },
    updated  => '2011-02-22T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'google maps version 3',
    id      => '6ce8624af05b0596f0c39e53b7b0987c',
    content => {
        type => 'text',
        content =>
qq{Fully use google maps version 3 for all maps on https://bbbike.org which enable new features like elevation charts and better support for mobile devices.},
    },
    updated  => '2011-02-07T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for New Dehli and Bombay',
    id      => 'e14f7b9315ebcbfeaf184a589400181b',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for New Dehli and Bombay: https://www.bbbike.org/Bombay and https://www.bbbike.org/NewDehli}
    },
    updated  => '2011-02-05T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      'New: cycle routing for Brazilian cities Curitiba and Porto Alegre',
    id      => 'e14f7b9315ebcbfeaf184a589400181c',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Brazilian cities Curitiba and Porto Alegre: https://www.bbbike.org/Curitiba and https://www.bbbike.org/PortoAlegre},
    },
    updated  => '2011-02-05T12:30:09Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for Potsdam and Oranienburg',
    id      => '3f1d0cba91c29c0e684bab966472936e',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Potsdam and Oranienburg: https://www.bbbike.org/Potsdam and https://www.bbbike.org/Oranienburg}
    },
    updated  => '2011-02-01T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for Lima and Montevideo',
    id      => '113b60839c9aafd096b0cfa8ac1e4235',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for South America: https://www.bbbike.org/Montevideo and https://www.bbbike.org/Lima},
    },
    updated  => '2011-01-31T12:30:12Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New: cycle routing for Palma de Majorca',
    id    => '0b29f549319e283e04bb67e2808a3d96',

    content => {
        type => 'text',
        content =>
qq{Now available - cycle routing for Palma and the island Majorca: https://www.bbbike.org/Palma/},
    },

    updated  => '2011-01-31T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'More translations to other languages',
    id    => '5569e78510bee2720280ed5cd3afee09',

    content => {
        type => 'text',
        content =>
qq{BBBike.org is now available in Danish, German, English, Spanish, French, Croatian, Dutch, Polish, Portuguese and Russian}
    },

    updated  => '2011-01-30T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New directory layout with shorter URLs',
    id    => '5569e78510bee2720280ed5cd3afee08',

    content => {
        type => 'text',
        content =>
qq{BBBike.org has now a new directory layout with a sub-directory for each city, e.g. the new home page for London is https://www.bbbike.org/London},
    },

    updated  => '2011-01-29T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Added new cities',
    id    => '8b4c4c5b6f1172986ef6cc55bcd0bd41',

    content => {
        type    => 'text',
        content => qq{New cities: Bochum},
    },

    updated  => '2010-12-31T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Added new cities',
    id    => '22bc165c483f77f67e3430b6505e83fa',

    content => {
        type    => 'text',
        content => qq{New cities: Bern},
    },

    updated  => '2010-12-15T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Added new cities',
    id    => '3b3feac5b7b9f2d4edca9fbeade6ddeb',

    content => {
        type => 'text',
        content =>
qq{New cities: Adelaide, Auckland, Brisbane, Buenos Aires, Canberra, Halifax, Johannesburg, Melbourne, Philadelphia},
    },

    updated  => '2010-11-27T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Weather forecast',
    id    => '61637f729905b8c61ac32a9fc4822077',

    content => {
        type => 'text',
        content =>
          qq{Display weather forecast for the next 4 days in local language.},
    },

    updated  => '2010-11-21T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Weather',
    id    => 'd156aa8e64721bff611a2d794fcbcf8e',

    content => {
        type    => 'text',
        content => qq{Display current weather conditions in local language.},
    },

    updated  => '2010-08-21T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New cities for England',
    id    => 'cfb1ddfbc43b4e93f9d20e729a2dea2e',

    content => {
        type => 'text',
        content =>
qq{New cities: Birmingham, Bristol, Leeds, Liverpool, Manchester, Sheffield},
    },

    updated  => '2010-08-21T12:30:05Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New cities for Scotland',
    id    => '527dad8380261ada331749b8a537af59',

    content => {
        type    => 'text',
        content => qq{New cities: Edinburgh, Glasgow},
    },

    updated  => '2010-08-21T12:30:06Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Donatations',
    id    => 'e86b828855a4103bfe73aa02fef7fa3a',

    content => {
        type => 'text',
        content =>
          qq{We accecpt donations! ;-) https://bbbike.org/community.html},
    },

    updated  => '2010-08-15T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Twitter',
    id    => 'e86b828855a4103bfe73aa02fef7fa3b',

    content => {
        type    => 'text',
        content => qq{BBBike is on https://twitter.com/BBBikeWorld! },
    },

    updated  => '2010-08-14T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Google Maps v3',
    id    => '384a4805c8a4b03c2b034a1b8a3fe83f',

    content => {
        type => 'text',
        content =>
qq{BBBike supports now google maps version 3 which enable new features like localization and elevation charts.},
    },

    updated  => '2010-08-02T18:30:42Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Additional map type terrain',
    id    => '23c619077a199e8ad171617ab24c7eb8',

    content => {
        type    => 'text',
        content => qq{Additional map type terrain},
    },

    updated  => '2010-08-02T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Redesign of BBBike',
    id    => '9bcb8fcbc414515b4ad98ca3d1dac9f4',

    content => {
        type    => 'text',
        content => qq{Redesign of BBBike\@world search page.},
    },

    updated  => '2010-07-31T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Plotting Street Names',
    id    => '7c0e10e5b40c4423c8a3f0b37772028f',

    content => {
        type => 'text',
        content =>
          qq{The street names will be plotted as you type in Google Maps.},
    },

    updated  => '2010-07-30T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'More cities supported: Bamberg',
    id    => '5906fa459866ba81323e4b5ba6411588',

    content => {
        type    => 'text',
        content => qq{Added new cities: Bamberg},
    },

    updated  => '2010-07-23T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'More cities supported',
    id    => '74ce830fecbcbe6fe07c3f61df1f5176',

    content => {
        type    => 'text',
        content => qq{Added new cities: Victoria},
    },

    updated  => '2010-06-15T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Elevation chart',
    link  => $homepage,
    id    => '81ebeaf0506f9d6a518be2ab38ec243f',

    content => {
        type    => 'text',
        content => qq{BBBike\@World displays the elevation chart for the route.}
    },

    updated  => '2010-04-11T18:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title => 'More cities supported',
    id    => '82ebeaf0506f9d6a518be2ab38ec242d',

    content => {
        type => 'text',
        content =>
qq{Added new cities: Nuernberg, Muenchen, Kiel, Oldenburg, Genf, Warschau, Magdeburg, Posen, Breslau, Kattowitz, and Gleiwitz.},
    },

    updated  => '2010-03-12T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New design for BBBike\@world search',
    link  => $homepage,
    id    => '3954a6fca12368526e8c790e38bcb743',

    content => {
        type    => 'text',
        content => qq{New design for BBBike\@world search}
    },

    updated  => '2010-03-06T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New cities for BBBike\@world',
    link  => $homepage,
    id    => '81ebeaf0506f9d6a518be2ab38ec243d',

    content => {
        type    => 'text',
        content => qq{BBBike\@World supports now 125 cities world wide.}
    },

    updated  => '2010-03-06T18:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Updated BBBike\@Berlin packages for MacOS',
    link  => 'https://bbbike.sourceforge.net/downloads.en.html',
    id    => '81ebeaf0506f9d6a518be2ab38ec243e',

    content => {
        type    => 'text',
        content => qq{The BBBike\@Berlin package for MacOS are updated.}
    },

    updated  => '2010-03-06T18:30:04Z',
    category => 'News',
);

$feed->add_entry(
    title => 'OpenSearch search plugins',
    id    => '81ebeaf0506f9d6a518be2ab38ec244d',

    content => {
        type => 'text',
        content =>
          qq{Added support for OpenSearch search plugins for all cities.},
    },

    updated  => '2010-03-05T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Slippymap supports cycle map',
    id    => '81ebeaf0506f9d6a518be2ab38ec242d',

    content => {
        type    => 'text',
        content => qq{Added support for cycle map layer.},
    },

    updated  => '2010-01-03T18:30:02Z',
    category => 'News',
);

$feed->print;
