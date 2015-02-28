/*
 * Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
 */

/* global variables */

// HTML5: may not work on Android devices!
//"use strict"
// Initialise the 'map' object
var map;

var config = {
    minZoomLevel: 9,
    debug: 1
};

var state = {
    debug_time: {
        "start": $.now(),
        "last": $.now()
    },
    vectors: {},
    // polygon 
    box: 0
}; /* end of global variables */


function download_init_map() {
    map = new OpenLayers.Map("map", {
        controls: [new OpenLayers.Control.Navigation(), new OpenLayers.Control.PanZoom, new OpenLayers.Control.ScaleLine({
            geodesic: true
        }), new OpenLayers.Control.MousePosition(), new OpenLayers.Control.Attribution(), new OpenLayers.Control.LayerSwitcher()],
        maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34),
        maxResolution: 156543.0339,
        numZoomLevels: 17,
        units: 'm',
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326")
    });

    map.addLayer(new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik", {
        attribution: '<a href="http://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM.CycleMap("OSM CycleMap", {
        attribution: '<a href="http://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>, <a href="http://www.opencyclemap.org/">(&copy) OpenCycleMap</a>'
    }));

    map.zoomToMaxExtent();
    download_init_vectors(map);
}

function download_init_vectors(map) {
    // main vector
    state.vectors = new OpenLayers.Layer.Vector("Vector Layer", {
        displayInLayerSwitcher: false,

        styleMap: new OpenLayers.StyleMap({
            fillOpacity: 0.5,
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
    });
}

function download_plot_polygon(obj) {
    debug("download plot polygon");

    var polygon = obj.coords ? string2coords(obj.coords) : rectangle2polygon(obj.sw_lng, obj.sw_lat, obj.ne_lng, obj.ne_lat);
    var color = $("span." + obj.class_format).css("color");
    debug("class_format: " + obj.class_format + " color: " + color);

    var feature = plot_polygon(polygon, { type: color });
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
    debug("center city: " + sw_lng + "," + sw_lat + " " + ne_lng + "," + ne_lat);

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var bounds = new OpenLayers.Bounds(sw_lng, sw_lat, ne_lng, ne_lat);

    bounds.transform(epsg4326, map.getProjectionObject());
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

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var points = [];
    for (var i = 0; i < poly.length; i++) {
        var point = new OpenLayers.Geometry.Point(poly[i][0], poly[i][1]);
        point.transform(epsg4326, map.getProjectionObject());
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


/* main */
$(document).ready(function () {
    download_init_map();
    parse_areas_from_links();
});
