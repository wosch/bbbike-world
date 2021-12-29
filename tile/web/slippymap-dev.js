/* Copyright (c) 2011 OpenLayers
 * Copyright (c) 2012-2018 Wolfram Schneider, https://bbbike.org
 * /

/* run JavaScript code in strict mode, HTML5 */
"use strict";

// Start position for the map (hardcoded here for simplicity)
var lat = 52.51703;
var lon = 13.38885;
var zoom = 15;

var map; //complex object of type OpenLayers.Map
//Initialise the 'map' object

function init() {
    initKeyPress();

    var layer_options = {
        tileOptions: {
            crossOriginKeyword: null
        },
        sphericalMercator: true,
        // buffer: 0,
        transitionEffect: "resize",
        numZoomLevels: 19
    };

    // create the custom layer for toolserver.org
    OpenLayers.Layer.OSM.Toolserver = OpenLayers.Class(OpenLayers.Layer.OSM, {
        initialize: function (name, path, options) {
            var url = ["https://tiles.wmflabs.org/" + path + "/${z}/${x}/${y}.png", "http://b.tiles.wmflabs.org/" + path + "/${z}/${x}/${y}.png", "http://c.tiles.wmflabs.org/" + path + "/${z}/${x}/${y}.png"];

            options = OpenLayers.Util.extend({
                tileOptions: {
                    crossOriginKeyword: null
                },
                numZoomLevels: 19
            }, options);
            OpenLayers.Layer.OSM.prototype.initialize.apply(this, [name, url, options]);
        },

        CLASS_NAME: "OpenLayers.Layer.OSM.Toolserver"
    });

    map = new OpenLayers.Map("map", {
        controls: [
        new OpenLayers.Control.Navigation(), new OpenLayers.Control.PanZoomBar(), new OpenLayers.Control.Permalink(), new OpenLayers.Control.ScaleLine({
            geodesic: true
        }), new OpenLayers.Control.Permalink('permalink'), new OpenLayers.Control.MousePosition(), new OpenLayers.Control.Attribution()],
        maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34),
        maxResolution: 156543.0339,
        numZoomLevels: 19,
        units: 'm',
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326")
    });
    map.addControl(new OpenLayers.Control.KeyboardDefaults({
        observeElement: document.getElementById("map")
    }));

    // This is the layer that uses the locally stored tiles
    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org bbbike", "https://d.tile.bbbike.org/osm/bbbike/${z}/${x}/${y}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19,
        attribution: '<a href="https://bbbike.org/">BBBike.org</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org bbbike local", "/osm/bbbike/${z}/${x}/${y}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19,
        attribution: '<a href="https://bbbike.org/">BBBike.org</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik"));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Mapnik (de)", "https://a.tile.openstreetmap.de/tiles/osmde/${z}/${x}/${y}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM Mapnik b/w", 'bw-mapnik'));

    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM no labels", 'osm-no-labels'));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Toner", ["http://a.tile.stamen.com/toner/${z}/${x}/${y}.png", "http://b.tile.stamen.com/toner/${z}/${x}/${y}.png"], {
        numZoomLevels: 18
    }));
    map.addLayer(new OpenLayers.Layer.OSM("OSM Watercolor", ["http://a.tile.stamen.com/watercolor/${z}/${x}/${y}.png", "http://b.tile.stamen.com/watercolor/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Transport", ["http://a.tile2.opencyclemap.org/transport/${z}/${x}/${y}.png", "http://b.tile2.opencyclemap.org/transport/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Landscape", ["http://a.tile3.opencyclemap.org/landscape/${z}/${x}/${y}.png", "http://b.tile3.opencyclemap.org/landscape/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM OEPNV", [" http://tile.memomaps.de/tilegen/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Hike&Bike", ["https://tiles.wmflabs.org/hikebike/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM.CycleMap("OSM CycleMap"));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Wanderreitkarte", ["http://www.wanderreitkarte.de/topo/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM('Lyrk (OSM)', "https://tiles.lyrk.org/ls/${z}/${x}/${y}?apikey=e9f8eb3824344d18a5b4b657773caf30", layer_options)),

    map.addLayer(new OpenLayers.Layer.OSM('Lyrk Retina (OSM)', "https://tiles.lyrk.org/lr/${z}/${x}/${y}?apikey=e9f8eb3824344d18a5b4b657773caf30", layer_options)),

    map.addLayer(new OpenLayers.Layer.OSM("MapBox Satellite", ["https://api.mapbox.com/v4/mapbox.satellite/${z}/${x}/${y}@2x.jpg90?access_token=pk.eyJ1IjoibWFwcXVlc3QiLCJhIjoiY2Q2N2RlMmNhY2NiZTRkMzlmZjJmZDk0NWU0ZGJlNTMifQ.mPRiEubbajc6a5y9ISgydg"], {
        numZoomLevels:20 
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Maptookit Topo (OSM)", ['http://tile1.maptoolkit.net/terrain/${z}/${x}/${y}.png', 'http://tile2.maptoolkit.net/terrain/${z}/${x}/${y}.png'], {
        numZoomLevels: 19,
        tileOptions: {
            crossOriginKeyword: null
        },
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri", "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/${z}/${y}/${x}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri Topographic", "https://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/${z}/${y}/${x}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Skobbler (OSM)", ["http://tiles1.skobbler.net/osm_tiles2/${z}/${x}/${y}.png", "http://tiles2.skobbler.net/osm_tiles2/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19
    }));

    function bing() {
        var apiKey = "AjkRC9uldL9KVU3pa6N59e7fjpNdCzKTtMqFhdafSEQlcNGPLVEm3b3mukoZCLWr";

        // var map = new OpenLayers.Map( 'map');
        // XXX: bing.com returns a wrong zoom level in JSON API call
        var road = new OpenLayers.Layer.Bing(OpenLayers.Util.extend({
            initLayer: function () {
                // pretend we have a zoomMin of 0
                this.metadata.resourceSets[0].resources[0].zoomMin = 0;
                OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
            }
        }, {
            key: apiKey,
            type: "Road",
            // custom metadata parameter to request the new map style - only useful
            // before May 1st, 2011
            metadataParams: {
                mapVersion: "v1"
            }
        }));

        var aerial = new OpenLayers.Layer.Bing(OpenLayers.Util.extend({
            initLayer: function () {
                // pretend we have a zoomMin of 0
                this.metadata.resourceSets[0].resources[0].zoomMin = 0;
                OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
            }
        }, {
            key: apiKey,
            type: "Aerial",
            'numZoomLevels': 18
        }));

        var hybrid = new OpenLayers.Layer.Bing(OpenLayers.Util.extend({
            initLayer: function () {
                // pretend we have a zoomMin of 0
                this.metadata.resourceSets[0].resources[0].zoomMin = 0;
                OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
            }
        }, {
            key: apiKey,
            type: "AerialWithLabels",
            name: "Bing Aerial With Labels",
            'numZoomLevels': 18
        }));

        map.addLayers([road, aerial, hybrid]);
    };
    bing();

    // http://xbb.uz/openlayers/i-Yandex.Maps

    function yandex_getTileURL(bounds) {
        var r = this.map.getResolution();
        var maxExt = (this.maxExtent) ? this.maxExtent : YaBounds;
        var w = (this.tileSize) ? this.tileSize.w : 256;
        var h = (this.tileSize) ? this.tileSize.h : 256;
        var x = Math.round((bounds.left - maxExt.left) / (r * w));
        var y = Math.round((maxExt.top - bounds.top) / (r * h));
        var z = this.map.getZoom();
        var lim = Math.pow(2, z);
        if (y < 0 >= lim) {
            return OpenLayers.Util.getImagesLocation() + "404.png";
        } else {
            x = ((x % lim) + lim) % lim;
            // var url = (this.url) ? this.url : "http://vec02.maps.yandex.net/tiles?l=map&v=2.2.3";
            var url = (this.href) ? this.href : "http://sat01.maps.yandex.net/tiles?l=sat&v=1.35.0";
            return url + "&x=" + x + "&y=" + y + "&z=" + z;
        }
    };

    var YaBounds = new OpenLayers.Bounds(-20037508, -20002151, 20037508, 20072865);

    // Объект карты
    // maxExtent: YaBounds,
    map.addLayer(new OpenLayers.Layer.TMS("Yandex Maps", "", {
        maxExtent: YaBounds,
        href: "http://vec02.maps.yandex.net/tiles?l=map&v=2.2.3",
        getURL: yandex_getTileURL,
        numZoomLevels: 14,
        attribution: '<a href="http://beta-maps.yandex.ru/">Яндекс.Карты</a>'
    }));

    map.addLayer(new OpenLayers.Layer.TMS("Yandex Sat", "", {
        maxExtent: YaBounds,
        href: "http://sat01.maps.yandex.net/tiles?l=sat&v=1.35.0",
        getURL: yandex_getTileURL,
        numZoomLevels: 14,
        attribution: '<a href="http://beta-maps.yandex.ru/">Яндекс.Карты</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Waze", ["http://worldtiles1.waze.com/tiles/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19
    }));


    // This is the end of the layer
    // Begin of overlay
    map.addLayer(new OpenLayers.Layer.TMS("BBBike Fahrbahnqualit&auml;t", "https://d.tile.bbbike.org/osm/bbbike-smoothness/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("BBBike handicap", "https://d.tile.bbbike.org/osm/bbbike-handicap/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("BBBike cycle routes", "https://d.tile.bbbike.org/osm/bbbike-cycle-routes/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("BBBike cycleway", "https://d.tile.bbbike.org/osm/bbbike-cycleway/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("BBBike green", "https://d.tile.bbbike.org/osm/bbbike-green/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("BBBike unknown", "https://d.tile.bbbike.org/osm/bbbike-unknown/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("BBBike unlit", "https://d.tile.bbbike.org/osm/bbbike-unlit/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://bbbike.de/">BBBike</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.TMS("Land Shading", "http://tiles2.openpistemap.org/landshaded/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://tiles2.openpistemap.org/landshaded/">Land Shading</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 19,
        noOpaq: true
    }));

    var switcherControl = new OpenLayers.Control.LayerSwitcher();
    map.addControl(switcherControl);
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    map.addControl(new OpenLayers.Control.Permalink());
    // switcherControl.maximizeControl();
    // bbbike?

    function osm_getTileURL(bounds) {
        var res = this.map.getResolution();
        var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
        var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
        var z = this.map.getZoom();
        var limit = Math.pow(2, z);

        if (y < 0 || y >= limit) {
            return OpenLayers.Util.getImagesLocation() + "404.png";
        } else {
            x = ((x % limit) + limit) % limit;
            return this.url + z + "/" + x + "/" + y + "." + this.type;
        }
    }

    if (!map.getCenter()) {
        var lonLat = new OpenLayers.LonLat(lon, lat).transform(new OpenLayers.Projection("EPSG:4326"), map.getProjectionObject());
        map.setCenter(lonLat, zoom);
    }

    resizeBaseLayer();
    initBaseLayerHeight();
}

function initBaseLayerHeight() {
    var timer = null;

    // wait for  the last resize event, and 0.5 seconds later resize base layer height    
    window.onresize = function (event) {
        if (timer) clearTimeout(timer);
        timer = setTimeout(function () {
            resizeBaseLayer()
        }, 1000);
    }
}

/*
 resize base/data layer menu based on
 the actual window size. The base layer
 get 65% and the overlay layer 35% of the screen
*/
function resizeBaseLayer() {
    var style;

    var height = document.body.clientHeight;
    if (height <= 0) return;

    height -= 120; // top, copyright
    var base = parseInt(height * 0.65);
    var data = parseInt(height * 0.35);

    var style = document.createElement("style");
    var rules = document.createTextNode('.baseLayersDiv { max-height: ' + base + 'px; } .dataLayersDiv { max-height: ' + data + 'px; }');
    style.type = "text/css";

    var head = document.getElementsByTagName("head")[0];
    style.appendChild(rules);

    head.appendChild(style);
    // alert("base: " + base + " data: " + data);
}

/*
  here are dragons!
  code copied from js/OpenLayers-2.11/OpenLayers.js: OpenLayers.Control.KeyboardDefaults

  see also: http://www.mediaevent.de/javascript/Extras-Javascript-Keycodes.html
*/
function initKeyPress() {
    OpenLayers.Control.KeyboardDefaults.prototype.defaultKeyPress = function (evt) {
        switch (evt.keyCode) {

        case OpenLayers.Event.KEY_LEFT:
        case 72:
            moveMap(-this.slideFactor, 0);
            break;
        case OpenLayers.Event.KEY_RIGHT:
        case 76:
            moveMap(this.slideFactor, 0);
            break;
        case OpenLayers.Event.KEY_UP:
        case 75:
            moveMap(0, -this.slideFactor);
            break;
        case OpenLayers.Event.KEY_DOWN:
        case 74:
            moveMap(0, this.slideFactor);
            break;

        case 33:
            var size = this.map.getSize();
            this.map.pan(0, -0.75 * size.h);
            break;
        case 34:
            var size = this.map.getSize();
            this.map.pan(0, 0.75 * size.h);
            break;
        case 35:
            var size = this.map.getSize();
            this.map.pan(0.75 * size.w, 0);
            break;
        case 36:
            var size = this.map.getSize();
            this.map.pan(-0.75 * size.w, 0);
            break;

            // '+', '=''
        case 43:
        case 61:
        case 187:
        case 107:
        case 171:
            // Firefox 15.x
            this.map.zoomIn();
            break;

            // '-'
        case 45:
        case 109:
        case 189:
        case 95:
        case 173:
            // Firefox 15.x or later, see https://github.com/openlayers/openlayers/issues/605
            this.map.zoomOut();
            break;

        case 71:
            // 'g'
            locateMe();
            break;
        case 48:
            for (var i = 0; i < 17; i++) {
                if (this.map.getZoom() < i) this.map.zoomIn();
            }
            break;
        }
    };
};

// 1;
