/*
 * Copyright (c) 2012-2022 Wolfram Schneider, https://bbbike.org
 */

/* global variables */

// HTML5: may not work on Android devices!
//"use strict"
// Initialise the 'map' object
var map;

var config = {
    minZoomLevel: 10,
    map_height_factor: 0.4,
    /* hight of map, relative to window height: 0 .. 1 */
    debug: 1
};

var state = {
    debug_time: {
        "start": $.now(),
        "last": $.now()
    },
    epsg4326: new OpenLayers.Projection("EPSG:4326"),
    vectors: {},

    map_height_factor: config.map_height_factor,
    /* to reset full screen */

    // polygon 
    box: 0
}; /* end of global variables */


function download_init_map(conf) {
    if (!conf) conf = {}; // init
    map = new OpenLayers.Map("map", {
        controls: [
        new OpenLayers.Control.Navigation(), //
        new OpenLayers.Control.PanZoom, //
        new OpenLayers.Control.ScaleLine({
            geodesic: true
        }), // 
        new OpenLayers.Control.MousePosition(), //
        new OpenLayers.Control.Attribution(), //
        new OpenLayers.Control.LayerSwitcher() //
        // new OpenLayers.Control.KeyboardDefaults({}) //
        ],
        maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34),
        maxResolution: 156543.0339,
        numZoomLevels: 17,
        units: 'm',
        wrapDateLine: true,

        // most extracts are in the northern hemisphere,
        // set center to Central Europe
        center: new OpenLayers.LonLat(0, 35).transform(state.epsg4326, new OpenLayers.Projection("EPSG:900913")),

        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: state.epsg4326
    });

    map.addLayer(new OpenLayers.Layer.OSM("OSM Landscape", ["https://a.tile.thunderforest.com/landscape/${z}/${x}/${y}@2x.png?apikey=6170aad10dfd42a38d4d8c709a536f38", "https://b.tile.thunderforest.com/landscape/${z}/${x}/${y}@2x.png?apikey=6170aad10dfd42a38d4d8c709a536f38"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        attribution: '<a href="https://www.OpenStreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>, <a href="https://www.opencyclemap.org/">(&copy) OpenCycleMap</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik", {
        attribution: '<a href="https://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM.CycleMap("OSM CycleMap", {
        attribution: '<a href="https://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>, <a href="https://www.opencyclemap.org/">(&copy) OpenCycleMap</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapbox Satellite", ["https://api.mapbox.com/v4/mapbox.satellite/${z}/${x}/${y}@2x.jpg90?access_token=pk.eyJ1IjoibWFwcXVlc3QiLCJhIjoiY2Q2N2RlMmNhY2NiZTRkMzlmZjJmZDk0NWU0ZGJlNTMifQ.mPRiEubbajc6a5y9ISgydg"], {
        attribution: '<a href="https://www.mapbox.com/">(&copy) mapbox</a>',
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 20
    }));

    // Bing roads and Satellite/Hybrid
    // disabled due wrong billing
    // Bing roads and Satellite/Hybrid
    // add_bing_maps(map);
    download_init_vectors(map, conf);

    // by default we center the world map, otherwise use {nocenter: true}
    if (!conf.nocenter) {
        // var center = new OpenLayers.LonLat(0, 35).transform(state.epsg4326, map.getProjectionObject());
        // map.setCenter(center, 2);
        map.zoomTo(2);
    }

    init_map_resize();
}

function add_bing_maps(map) {
    var BingApiKey = "Aoz29UA0N53MbZ8SejgNnWib-_gW-JgHNwsSh77gzBZAyqEVRiJqRJ4ddJ5PXLXY";

    /* bing road */
    map.addLayer(new OpenLayers.Layer.Bing(
    // XXX: bing.com returns a wrong zoom level in JSON API call
    OpenLayers.Util.extend({
        initLayer: function () {
            // pretend we have a zoomMin of 0
            // resources may not exists if the service is down, or the bing key expired
            if (this.metadata.resourceSets[0] && this.metadata.resourceSets[0].resources) {
                this.metadata.resourceSets[0].resources[0].zoomMin = 0;
                OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
            } else {
                debug("Cannot find bing metadata resources, give up bing layer road");
            }
        }
    }, {
        key: BingApiKey,
        type: "Road"
        //,  metadataParams: { mapVersion: "v1" }
    })));

    /* bing hybrid */
    map.addLayer(new OpenLayers.Layer.Bing(OpenLayers.Util.extend({
        initLayer: function () {
            // resources may not exists if the service is down, or the bing key expired
            if (this.metadata.resourceSets[0] && this.metadata.resourceSets[0].resources) {
                this.metadata.resourceSets[0].resources[0].zoomMin = 0;
                OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
            } else {
                debug("Cannot find bing metadata resources, give up bing layer hybrid");
            }
        }
    }, {
        key: BingApiKey,
        type: "AerialWithLabels",
        name: "Bing Hybrid",
        numZoomLevels: 18
    })));
}


function download_init_vectors(map, conf) {
    if (!conf) conf = {}; // init
    // main vector
    var fillOpacity = conf.fillOpacity ? conf.fillOpacity : 0.5;
    debug("fillOpacity: " + fillOpacity);

    state.vectors = new OpenLayers.Layer.Vector("Vector Layer", {
        displayInLayerSwitcher: false,

        styleMap: new OpenLayers.StyleMap({
            fillOpacity: fillOpacity,
            fillColor: "${type}",
            // based on feature.attributes.type
            strokeColor: "${type}" // based on feature.attributes.type
        })
    });

    map.addLayer(state.vectors);
}

function get_download_area(url) {
    var params = OpenLayers.Util.getParameters(url, {
        "splitArgs": false
    });

    // put the extracted parameters into an object
    var obj = {
        sw_lng: params.sw_lng,
        sw_lat: params.sw_lat,
        ne_lng: params.ne_lng,
        ne_lat: params.ne_lat,
        coords: params.coords,
        format: params.format,
        city: params.city
    };

    return obj;
}

/* extract coordinates from links on the fly after page load */

function parse_areas_from_links() {
    $("td > a.polygon0, td > a.polygon1").each(function (i, n) {
        setTimeout(function () {
            var url = $(n).attr("href");
            var obj = get_download_area(url);

            // get class format from the <td> before
            obj.class_format = $($(n).parent().parent().find("td > span")[1]).attr("class");

            // display *all* polygons first, looks nicer
            download_plot_polygon(obj);

            // on mouseover, move to the polygon and center
            $(n).on("mouseover", "", function () {
                download_center_polygon(obj);
            });

        }, 0 * i);
    });
}

function download_plot_polygon(obj) {
    debug("download plot polygon");

    var polygon = obj.coords ? string2coords(obj.coords) : rectangle2polygon(obj.sw_lng, obj.sw_lat, obj.ne_lng, obj.ne_lat);
    var color = obj.color ? obj.color : $("span." + obj.class_format).css("color");
    debug("class_format: " + obj.class_format + " color: " + color);

    var feature = plot_polygon(polygon, {
        type: color
    });
    state.vectors.addFeatures(feature);
}

/***********************************************************************************
 * shared code from extract.js
 * keep in sync!
 */

function string2coords(coords) {
    debug("string2coords: " + coords);

    var list = [];
    if (!coords) return list;

    var _list = coords.split("|");
    for (var i = 0; i < _list.length; i++) {
        var pos = _list[i].split(",");
        list.push(pos);
    }

    return list;
}


function center_city(sw_lng, sw_lat, ne_lng, ne_lat) {
    debug("center city: sw_lng: " + sw_lng + " sw_lat: " + sw_lat + " ne_lng: " + ne_lng + " ne_lat: " + ne_lat);

    var bounds = new OpenLayers.Bounds(sw_lng, sw_lat, ne_lng, ne_lat);

    bounds.transform(state.epsg4326, map.getProjectionObject());
    map.zoomToExtent(bounds);

    var zoom = map.getZoom();
    if (zoom > config.minZoomLevel) {
        map.zoomTo(config.minZoomLevel);
    }
}

function download_center_polygon(obj) {
    $("#debug").text("selected area: " + obj.city + ", format: " + obj.format); // no escape for .text() neeeded
    center_city(obj.sw_lng, obj.sw_lat, obj.ne_lng, obj.ne_lat);
}

/* create a polygon based on a points list, which can be added to a vector */

function plot_polygon(poly, styleObj) {
    debug("plot polygon, length: " + poly.length);

    var points = [];
    for (var i = 0; i < poly.length; i++) {
        var point = new OpenLayers.Geometry.Point(poly[i][0], poly[i][1]);
        point.transform(state.epsg4326, map.getProjectionObject());
        points.push(point);
    }

    var linear_ring = new OpenLayers.Geometry.LinearRing(points);
    var polygonFeature = new OpenLayers.Feature.Vector(new OpenLayers.Geometry.Polygon(linear_ring), styleObj);

    return polygonFeature;
}

/*
  create a 5 point polygon based on 2 rectangle points
*/
function rectangle2polygon(sw_lng, sw_lat, ne_lng, ne_lat) {
    var p = [];

    p.push([sw_lng, sw_lat]);
    p.push([ne_lng, sw_lat]);
    p.push([ne_lng, ne_lat]);
    p.push([sw_lng, ne_lat]);
    p.push([sw_lng, sw_lat]);

    return p;
}

function debug(text, id) {
    if (typeof console === "undefined" || typeof console.log === "undefined") { /* ARGH!!! old IE */
        return;
    }

    // no debug at all
    if (config.debug < 1) return;

    var now = $.now();
    var timestamp = (now - state.debug_time.start) / 1000 + " (+" + (now - state.debug_time.last) / 1000 + ") "
    state.debug_time.last = now;

    // log to JavaScript console
    console.log("BBBike download: " + timestamp + state.box + " " + text);

    // no debug on html page
    if (config.debug <= 1) return;

    if (!id) id = "debug";

    var tag = $("#" + id);
    if (!tag) return;

    // log to HTML page
    tag.html(timestamp + text);
}


function init_map_resize() {
    var resize = null;

    // set map height depending on the free space on the browser window
    setMapHeight();

    // reset map size, 3x a second
    $(window).resize(function () {
        if (resize) clearTimeout(resize);
        resize = setTimeout(function () {
            debug("resize event");
            setMapHeight();
        }, 100);
    });
}

function setMapHeight() {
    var height = $(window).height();
    var map_height = $("#map").height();
    var map_height_new = map_height;

    var map_height_default = 480;

    height = Math.floor(height);
    map_height = Math.floor(map_height);

    if (map_height * 2 >= height || map_height <= map_height_default) {
        map_height_new = Math.floor(height * state.map_height_factor);

        debug("setMapHeight: map: " + map_height_new + "px, total height: " + height + "px");
        $('#map').height(map_height_new);
        $('span#debug').css('top', map_height_new - 20);
        $('div#nomap').css('padding-top', map_height_new + 55);
    }
};

function toggle_fullscreen(args) {
    debug("toggle fullscreen, current state: " + state.map_height_factor);
    if (state.map_height_factor == config.map_height_factor) {
        state.map_height_factor = 1;
    } else {
        state.map_height_factor = config.map_height_factor;
    }

    setMapHeight();
    return state.map_height_factor;
}

var auto_refresh_timer;

function _auto_refresh(count, max, time, url) {
    // be fast on first click
    if (count == 0) {
        document.location.href = url;
    } else if (count < max) {
        auto_refresh_timer = setTimeout(function () {
            document.location.href = url;
        }, time * 1000);
    }
}

/* main
$(document).ready(function () {
    download_init_map();
    parse_areas_from_links();
});
*/
