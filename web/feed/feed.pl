#!/usr/bin/perl

use XML::Atom::SimpleFeed;

my $homepage = $ENV{'BBBIKE_HOMEPAGE'} || 'http://www.bbbike.org';

my $feed = XML::Atom::SimpleFeed->new(
    title   => 'BBBike @ World - a Cycle Route Planner',
    link    => $homepage,
    link    => { rel => 'self', href => $homepage . '/feed/bbbike-world.xml' },
    icon    => $homepage . '/images/srtbike.ico',
    updated => '2010-03-03T18:30:02Z',
    author  => 'Wolfram Schneider',
    subtitle =>
'BBBike is a route planner for cyclists in Berlin. It is now ported to other cities around the world - thanks to the OpenStreetMap project!',
    id => 'urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6',
);

######################################################################

$feed->add_entry(
    title   => 'New: cycle routing for Berkeley',
    id      => 'df1301be6fe83a6731d7840ee3408efa',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Berkeley, East Bay (San Francisco Bay Area): http://www.bbbike.org/Berkeley}
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
qq{Fully use google maps version 3 for all maps on http://bbbike.org which enable new features like elevation charts and better support for mobile devices.},
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
qq{New: cycle routing for New Dehli and Bombay: http://www.bbbike.org/Bombay and http://www.bbbike.org/NewDehli}
    },
    updated  => '2011-02-05T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title =>
      'New: cycle routing for Brazilian cities Curitiba and Porto Alegre',
    id      => 'e14f7b9315ebcbfeaf184a589400181b',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Brazilian cities Curitiba and Porto Alegre: http://www.bbbike.org/Curitiba and http://www.bbbike.org/PortoAlegre},
    },
    updated  => '2011-02-05T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title   => 'New: cycle routing for Potsdam and Oranienburg',
    id      => '3f1d0cba91c29c0e684bab966472936e',
    content => {
        type => 'text',
        content =>
qq{New: cycle routing for Potsdam and Oranienburg: http://www.bbbike.org/Potsdam and http://www.bbbike.org/Oranienburg}
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
qq{New: cycle routing for South America: http://www.bbbike.org/Montevideo and http://www.bbbike.org/Lima},
    },
    updated  => '2011-01-31T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New: cycle routing for Palma de Majorca',
    id    => '0b29f549319e283e04bb67e2808a3d96',

    content => {
        type => 'text',
        content =>
qq{Now available - cycle routing for Palma and the island Majorca: http://www.bbbike.org/Palma/},
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
    id    => '5569e78510bee2720280ed5cd3afee09',

    content => {
        type => 'text',
        content =>
qq{BBBike.org has now a new directory layout with a sub-directory for each city, e.g. the new home page for London is http://www.bbbike.org/London},
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

    updated  => '2010-08-21T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New cities for Scotland',
    id    => '527dad8380261ada331749b8a537af59',

    content => {
        type    => 'text',
        content => qq{New cities: Edinburgh, Glasgow},
    },

    updated  => '2010-08-21T12:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Donatations',
    id    => 'e86b828855a4103bfe73aa02fef7fa3a',

    content => {
        type => 'text',
        content =>
          qq{We accecpt donations! ;-) http://bbbike.org/community.html},
    },

    updated  => '2010-08-15T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Twitter',
    id    => 'e86b828855a4103bfe73aa02fef7fa3a',

    content => {
        type    => 'text',
        content => qq{BBBike is on http://twitter.com/BBBikeWorld! },
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

    updated  => '2010-08-02T18:30:02Z',
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
        content => qq{Redesign of BBBike @ world search page.},
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
        type => 'text',
        content =>
          qq{BBBike @ World displays the elevation chart for the route.}
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
    title => 'New design for BBBike @ world search',
    link  => $homepage,
    id    => '3954a6fca12368526e8c790e38bcb743',

    content => {
        type    => 'text',
        content => qq{New design for BBBike @ world search}
    },

    updated  => '2010-03-06T18:30:02Z',
    category => 'News',
);

$feed->add_entry(
    title => 'New cities for BBBike @ world',
    link  => $homepage,
    id    => '81ebeaf0506f9d6a518be2ab38ec243f',

    content => {
        type    => 'text',
        content => qq{BBBike @ World supports now 125 cities world wide.}
    },

    updated  => '2010-03-06T18:30:03Z',
    category => 'News',
);

$feed->add_entry(
    title => 'Updated BBBike @ Berlin packages for MacOS',
    link  => 'http://bbbike.sourceforge.net/downloads.en.html',
    id    => '81ebeaf0506f9d6a518be2ab38ec243e',

    content => {
        type    => 'text',
        content => qq{The BBBike @ Berlin package for MacOS are updated.}
    },

    updated  => '2010-03-06T18:30:04Z',
    category => 'News',
);

$feed->add_entry(
    title => 'OpenSearch search plugins',
    id    => '81ebeaf0506f9d6a518be2ab38ec243d',

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

