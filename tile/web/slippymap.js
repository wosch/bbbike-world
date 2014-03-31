/* Copyright (c) 2011 OpenLayers
 * Copyright (c) 2012-2014 Wolfram Schneider, http://bbbike.org
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
    // create the custom layer for toolserver.org
    OpenLayers.Layer.OSM.Toolserver = OpenLayers.Class(OpenLayers.Layer.OSM, {
        initialize: function (name, path, options) {
            var url = ["http://a.www.toolserver.org/tiles/" + path + "/${z}/${x}/${y}.png", "http://b.www.toolserver.org/tiles/" + path + "/${z}/${x}/${y}.png", "http://c.www.toolserver.org/tiles/" + path + "/${z}/${x}/${y}.png"];

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
    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org Mapnik (de)", "/osm/mapnik-german/${z}/${x}/${y}.png", {
        tileOptions: { crossOriginKeyword: null },
        numZoomLevels: 19,
        attribution: '<a href="http://bbbike.org/">BBBike.org</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org Mapnik", "/osm/mapnik/${z}/${x}/${y}.png", {
        tileOptions: { crossOriginKeyword: null },
        numZoomLevels: 19,
        attribution: '<a href="http://bbbike.org/">BBBike.org</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("BBBike.org bbbike", "/osm/bbbike/${z}/${x}/${y}.png", {
        numZoomLevels: 19,
        attribution: '<a href="http://bbbike.org/">BBBike.org</a>'
    }));
    
    map.addLayer(new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik"));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Mapnik (de)", "http://a.tile.openstreetmap.de/tiles/osmde/${z}/${x}/${y}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Mapnik b/w", "http://a.www.toolserver.org/tiles/bw-mapnik/${z}/${x}/${y}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

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

    map.addLayer(new OpenLayers.Layer.OSM("OSM Hike&Bike", ["http://a.www.toolserver.org/tiles/hikebike/${z}/${x}/${y}.png", "http://b.www.toolserver.org/tiles/hikebike/${z}/${x}/${y}.png"], {
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

    map.addLayer(new OpenLayers.Layer.OSM("MapBox (OSM)", ["http://a.tiles.mapbox.com/v3/examples.map-vyofok3q/${z}/${x}/${y}.png", "http://b.tiles.mapbox.com/v3/examples.map-vyofok3q/${z}/${x}/${y}.png"], {
        numZoomLevels: 17
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Maptookit Topo (OSM)", ['http://tile1.maptoolkit.net/terrain/${z}/${x}/${y}.png', 'http://tile2.maptoolkit.net/terrain/${z}/${x}/${y}.png'], {
        numZoomLevels: 19,
        tileOptions: {
            crossOriginKeyword: null
        },
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri", "http://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/${z}/${y}/${x}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri Topographic", "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/${z}/${y}/${x}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapquest EU (OSM)", ["http://otile1.mqcdn.com/tiles/1.0.0/osm/${z}/${x}/${y}.png", "http://otile2.mqcdn.com/tiles/1.0.0/osm/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapquest US (OSM)", ["http://mtile01.mqcdn.com/tiles/1.0.0/vy/map/${z}/${x}/${y}.png", "http://mtile02.mqcdn.com/tiles/1.0.0/vy/map/${z}/${x}/${y}.png"], {
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapquest Satellite", ["http://mtile01.mqcdn.com/tiles/1.0.0/vy/sat/${z}/${x}/${y}.png", "http://mtile02.mqcdn.com/tiles/1.0.0/vy/sat/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Skobbler (OSM)", ["http://tiles1.skobbler.net/osm_tiles2/${z}/${x}/${y}.png", "http://tiles2.skobbler.net/osm_tiles2/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Nokia("Nokia Map", {
        type: "normal.day",
        app_id: "SqE1xcSngCd3m4a1zEGb",
        token: "r0sR1DzqDkS6sDnh902FWQ"
    }));
    map.addLayer(new OpenLayers.Layer.Nokia("Nokia Terrain", {
        type: "terrain.day",
        app_id: "SqE1xcSngCd3m4a1zEGb",
        token: "r0sR1DzqDkS6sDnh902FWQ"
    }));
    map.addLayer(new OpenLayers.Layer.Nokia("Nokia Satellite", {
        type: "satellite.day",
        app_id: "SqE1xcSngCd3m4a1zEGb",
        token: "r0sR1DzqDkS6sDnh902FWQ"
    }));
    map.addLayer(new OpenLayers.Layer.Nokia("Nokia Hybrid", {
        type: "hybrid.day",
        app_id: "SqE1xcSngCd3m4a1zEGb",
        token: "r0sR1DzqDkS6sDnh902FWQ"
    }));
    map.addLayer(new OpenLayers.Layer.Nokia("Nokia Public Transit", {
        type: "normal.day.transit",
        app_id: "SqE1xcSngCd3m4a1zEGb",
        token: "r0sR1DzqDkS6sDnh902FWQ"
    }));
    map.addLayer(new OpenLayers.Layer.Nokia("Nokia Traffic", {
        type: "normal.day.grey",
        app_id: "SqE1xcSngCd3m4a1zEGb",
        token: "r0sR1DzqDkS6sDnh902FWQ"
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Apple iPhoto (OSM)", ["http://gsp2.apple.com/tile?api=1&style=slideshow&layers=default&lang=de_DE&z=${z}&x=${x}&y=${y}&v=9"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 15
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Physical", {
        type: google.maps.MapTypeId.TERRAIN,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 16
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Roadmap", {
        type: google.maps.MapTypeId.ROADMAP,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Satellite", {
        type: google.maps.MapTypeId.SATELLITE,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Hybrid", {
        type: google.maps.MapTypeId.HYBRID,
        'sphericalMercator': true,
        attribution: ', <a href="http://maps.google.com/">Google</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.Yahoo("Yahoo Street", {
        'sphericalMercator': true,
        attribution: '<a href="http://yahoo.com/">Yahoo Local Maps</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.Yahoo("Yahoo Aerial", {
        'type': YAHOO_MAP_SAT,
        'sphericalMercator': true,
        attribution: '<a href="http://yahoo.com/">Yahoo Local Maps</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.Yahoo("Yahoo Hybrid", {
        'type': YAHOO_MAP_HYB,
        'sphericalMercator': true,
        attribution: '<a href="http://yahoo.com/">Yahoo Local Maps</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.WMS("Soviet Military Topo", "http://www.topomapper.com/cgi-bin/tilecache-2.11b/tilecache.py", {
        layers: "topomapper_gmerc",
        format: 'image/jpeg'
    }, {
        'buffer': 1,
        srs: 'EPSG:900913',
        'numZoomLevels': 14,
        wrapDateLine: true,
        transparent: false,
        'attribution': 'Map data hosted by <a href="http://www.atlogis.com/">Atlogis</a>'
    }));
    // topomapper.setTileSize(new OpenLayers.Size(256, 256));
    // map.addLayer(topomapper);

    function bing() {
        var apiKey = "AqTGBsziZHIJYYxgivLBf0hVdrAk9mWO5cQcb8Yux8sW5M8c8opEC2lZqKR1ZZXf";

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

    map.addLayer(new OpenLayers.Layer.OSM("Waze", ["http://tiles1.waze.com/tiles/${z}/${x}/${y}.png", "http://tiles2.waze.com/tiles/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 19
    }));


    // This is the end of the layer
    // Begin of overlay
    map.addLayer(new OpenLayers.Layer.TMS("BBBike Fahrbahnqualit&auml;t", "/osm/bbbike-smoothness/", {
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

    map.addLayer(new OpenLayers.Layer.TMS("BBBike Fahrbahnqu. (solid)", "/osm/bbbike-smoothness-solid/", {
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
    
    map.addLayer(new OpenLayers.Layer.TMS("BBBike handicap", "/osm/bbbike-handicap/", {
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
        
    map.addLayer(new OpenLayers.Layer.TMS("BBBike cycle routes", "/osm/bbbike-cycle-routes/", {
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
    
    map.addLayer(new OpenLayers.Layer.TMS("BBBike cycleway", "/osm/bbbike-cycleway/", {
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
    
    map.addLayer(new OpenLayers.Layer.TMS("ADFC Radwegenetz", "", {
        type: 'png',
        getURL: get_mm_bikeTracks,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://www.adfc.de/">ADFC</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 17,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.XYZ("Velo-Layer", "http://toolserver.org/tiles/bicycle/${z}/${x}/${y}.png", {
        attribution: '<a href="http://osm.t-i.ch/bicycle/map/">Velo-Layer</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 18,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Toolserver('Bicycle Network', 'bicycle_network', {
        isBaseLayer: false,
        visibility: false,
        opacity: 0.8,
        numZoomLevels: 16
    }));

    map.addLayer(new OpenLayers.Layer.XYZ("Max Speed", "http://wince.dentro.info/koord/osm/tiles/${z}/${x}/${y}.png", {
        attribution: '<a href="http://wince.dentro.info/koord/osm/KosmosMap.htm">MaxSpeedMap</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 15,
        noOpaq: true
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Public Transport Lines", "http://www.openptmap.org/tiles/${z}/${x}/${y}.png", {
        tileOptions: {
            crossOriginKeyword: null
        },
        maxZoomLevel: 17,
        numZoomLevels: 18,
        alpha: true,
        isBaseLayer: false,
        visibility: false
    }));

    map.addLayer(new OpenLayers.Layer.TMS("Yandex Hybrid", "", {
        maxExtent: YaBounds,
        href: "http://vec01.maps.yandex.net/tiles?l=skl",
        getURL: yandex_getTileURL,
        numZoomLevels: 14,
        isBaseLayer: false,
        visibility: false,
        attribution: '<a href="http://beta-maps.yandex.ru/">Яндекс.Карты</a>'
    }));

    map.addLayer(new OpenLayers.Layer.TMS("Hillshading SRTM3 V2", "http://toolserver.org/~cmarqu/hill/", {
        type: 'png',
        getURL: osm_getTileURL,
        displayOutsideMaxExtent: true,
        attribution: '<a href="http://toolserver.org/~cmarqu/hill/">Hillshading SRTM3 V2</a>',
        opacity: 1,
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 17,
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

    map.addLayer(new OpenLayers.Layer.OSM.Toolserver('Parking', 'parktrans', {
        isBaseLayer: false,
        visibility: false,
        opacity: 0.8,
        numZoomLevels: 16
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver('Power Map', 'powermap', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 13
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Arabic (ar)", 'osm-labels-ar', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 13
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Chinese (zh)", 'osm-labels-zh', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 13
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels English (en)", 'osm-labels-en', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 18
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels French (fr)", 'osm-labels-fr', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 16
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels German (de)", 'osm-labels-de', {
        isBaseLayer: false,
        visibility: false
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Japanese (ja)", 'osm-labels-ja', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 13
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Korean (ko)", 'osm-labels-ko', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 13
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Polish (pl)", 'osm-labels-pl', {
        isBaseLayer: false,
        visibility: false
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Russian (ru)", 'osm-labels-ru', {
        isBaseLayer: false,
        visibility: false
    }));
    map.addLayer(new OpenLayers.Layer.OSM.Toolserver("OSM labels Spanish (es)", 'osm-labels-es', {
        isBaseLayer: false,
        visibility: false,
        numZoomLevels: 16
    }));

    var switcherControl = new OpenLayers.Control.LayerSwitcher();
    map.addControl(switcherControl);
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    map.addControl(new OpenLayers.Control.Permalink());
    // switcherControl.maximizeControl();
    // ADFC

    function get_mm_bikeTracks(bounds) {
        var llbounds = new OpenLayers.Bounds();
        llbounds.extend(OpenLayers.Layer.SphericalMercator.inverseMercator(bounds.left, bounds.bottom));
        llbounds.extend(OpenLayers.Layer.SphericalMercator.inverseMercator(bounds.right, bounds.top));
        var url = "http://mm-lbserver.dnsalias.com/mm-mapserver_v2/wms/wms.php?REQUEST=GetMap&SERVICE=WMS&VERSION=1.1.1&LAYERS=MM_BIKETRACKS&STYLES=&FORMAT=image/png&BGCOLOR=0xFFFFFF&TRANSPARENT=TRUE&SRS=EPSG:4326&BBOX="
        url = url + llbounds.toBBOX() + "&WIDTH=256&HEIGHT=256"
        return url
    }

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

// 1;
