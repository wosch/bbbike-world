/*
 Copyright (c) 2012-2015 Wolfram Schneider, http://bbbike.org
*/

// HTML5: may not work on Android devices!
//"use strict"
var map; // global map object

function download_init_map() {
    map = new OpenLayers.Map("map", {
        controls: [
        new OpenLayers.Control.Navigation(), new OpenLayers.Control.PanZoomBar(), new OpenLayers.Control.ScaleLine({
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
}

function get_download_area(url) {
    var params = OpenLayers.Util.getParameters(url);

    return {
        sw_lng: params.sw_lng,
        sw_lat: params.sw_lat,
        ne_lng: params.ne_lng,
        ne_lat: params.ne_lat,
        coords: params.coords,
        city: params.city,
        format: params.format
    }
}

function parse_areas_from_links() {
    var params = OpenLayers.Util.getParameters(this.base);

    $("td > a.polygon0, td > a.polygon1").each(function(i, n) {
        $(n).on("mouseover", "", function() {
            var url = $(n).attr("href");
            var obj = get_download_area(url);
            $("#debug").html(obj.format);
        });
    });
}

$(document).ready(function() {
    download_init_map();
    parse_areas_from_links();
});
