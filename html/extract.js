/*
 Copyright (c) by https://www.openstreetmap.org/export - OSM License, 2012
 Copyright (c) 2012-2021 Wolfram Schneider, https://bbbike.org
*/

// HTML5: may not work on Android devices!
//"use strict"
// central config
var config = {
    // open help page at start up
    "open_infopage": false,

    // run locate me function at startup
    "locate_me": false,

    // show approx. file size of extract
    "show_filesize": true,

    // city name required
    "city_name_optional": false,
    "city_name_check": true,

    // box must be on map before submit
    "box_on_map": true,

    // limit are size to max. square kilometers
    // keep in sync with lib/Extract/Config.pm !!!
    "max_skm": 24000000,

    // max. area size in MB
    "max_size": {
        "default": 512,

        "osm.pbf": 520,

        "text.xz": 496,
        "geojson.xz": 496,
        "geojsonseq.xz": 496,
        "sqlite.xz": 256,

        "mbtiles-openmaptiles.zip": 48,
        "mbtiles-basic.zip": 48,

        "obf.zip": 256,
        "navit.zip": 512,
        "bbbike-perltk.zip": 90,
        "shp.zip": 128,
        "mapsforge-osm.zip": 320,
        "mapsme-osm.zip": 500,

        "garmin-bbbike.zip": 512,
        "garmin-bbbike-ascii.zip": 512,
        "garmin-bbbike-latin1.zip": 512,
        "garmin-osm.zip": 512,
        "garmin-osm-ascii.zip": 512,
        "garmin-osm-latin1.zip": 512,
        "garmin-cycle.zip": 512,
        "garmin-cycle-ascii.zip": 512,
        "garmin-cycle-latin1.zip": 512,
        "garmin-leisure.zip": 512,
        "garmin-leisure-ascii.zip": 512,
        "garmin-leisure-latin1.zip": 512,
        "garmin-onroad.zip": 250,
        "garmin-onroad-ascii.zip": 250,
        "garmin-onroad-latin1.zip": 250,
        "garmin-ontrail.zip": 200,
        "garmin-ontrail-ascii.zip": 200,
        "garmin-ontrail-latin1.zip": 200,
        "garmin-opentopo.zip": 512,
        "garmin-opentopo-ascii.zip": 512,
        "garmin-opentopo-latin1.zip": 512,
        "garmin-openfietslite.zip": 512,
        "garmin-openfietslite-ascii.zip": 512,
        "garmin-openfietslite-latin1.zip": 512,
        "garmin-openfietsfull.zip": 512,
        "garmin-openfietsfull-ascii.zip": 512,
        "garmin-openfietsfull-latin1.zip": 512,
        "garmin-oseam.zip": 512,
        "garmin-oseam-ascii.zip": 512,
        "garmin-oseam-latin1.zip": 512,

        "png-google.zip": 24,
        "png-osm.zip": 24,
        "png-urbanight.zip": 32,
        "png-wireframe.zip": 32,
        "png-cadastre.zip": 8,

        "svg-google.zip": 24,
        "svg-osm.zip": 24,
        "svg-hiking.zip": 24,
        "svg-urbanight.zip": 32,
        "svg-wireframe.zip": 32,
        "svg-cadastre.zip": 8,

        "srtm-europe.garmin-srtm.zip": 800,
        "srtm-europe.obf.zip": 200,
        "srtm.garmin-srtm.zip": 800,
        "srtm.obf.zip": 200
    },

    max_skm_format: {
        "png-google.zip": 900,
        "png-osm.zip": 900,
        "png-hiking.zip": 900,
        "png-urbanight.zip": 900,
        "png-wireframe.zip": 900,
        "png-cadastre.zip": 900,

        "svg-google.zip": 900,
        "svg-osm.zip": 900,
        "svg-urbanight.zip": 900,
        "svg-wireframe.zip": 900,
        "svg-cadastre.zip": 900
    },

    // help image per format
    "format_images": {
        "garmin-openfietslite.zip": "/images/garmin-openfietslite-small.png",
        "garmin-openfietslite-ascii.zip": "/images/garmin-openfietslite-small.png",
        "garmin-openfietslite-latin1.zip": "/images/garmin-openfietslite-small.png",
        "garmin-openfietsfull.zip": "/images/garmin-openfietsfull-small.png",
        "garmin-openfietsfull-ascii.zip": "/images/garmin-openfietsfull-small.png",
        "garmin-openfietsfull-latin1.zip": "/images/garmin-openfietsfull-small.png",
        "garmin-onroad.zip": "/images/garmin-onroad2-small.png",
        "garmin-onroad-ascii.zip": "/images/garmin-onroad2-small.png",
        "garmin-onroad-latin1.zip": "/images/garmin-onroad2-small.png",
        "garmin-ontrail.zip": "/images/garmin-ontrail2-small.png",
        "garmin-ontrail-ascii.zip": "/images/garmin-ontrail2-small.png",
        "garmin-ontrail-latin1.zip": "/images/garmin-ontrail2-small.png",
        "garmin-opentopo.zip": "/images/garmin-opentopo-berlin-120.png",
        "garmin-opentopo-ascii.zip": "/images/garmin-opentopo-berlin-120.png",
        "garmin-opentopo-latin1.zip": "/images/garmin-opentopo-berlin-120.png",
        "garmin-bbbike.zip": "/images/garmin-bbbike-small.png",
        "garmin-bbbike-ascii.zip": "/images/garmin-bbbike-small.png",
        "garmin-bbbike-latin1.zip": "/images/garmin-bbbike-small.png",
        "garmin-cycle.zip": "/images/garmin-cycle-small.png",
        "garmin-cycle-ascii.zip": "/images/garmin-cycle-small.png",
        "garmin-cycle-latin1.zip": "/images/garmin-cycle-small.png",
        "garmin-leisure.zip": "/images/garmin-leisure-small.png",
        "garmin-leisure-ascii.zip": "/images/garmin-leisure-small.png",
        "garmin-leisure-latin1.zip": "/images/garmin-leisure-small.png",
        "garmin-osm.zip": "/images/garmin-osm-small.png",
        "garmin-osm-ascii.zip": "/images/garmin-osm-small.png",
        "garmin-osm-latin1.zip": "/images/garmin-osm-small.png",
        "garmin-oseam.zip": "/images/garmin-oseam2-small.png",
        "garmin-oseam-ascii.zip": "/images/garmin-oseam2-small.png",
        "garmin-oseam-latin1.zip": "/images/garmin-oseam2-small.png",

        "svg-google.zip": "/images/svg-google-small.png",
        "svg-osm.zip": "/images/svg-osm-small.png",
        "svg-hiking.zip": "/images/svg-hiking-small.png",
        "svg-urbanight.zip": "/images/svg-urbanight-small.png",
        "svg-wireframe.zip": "/images/svg-wireframe-small.png",
        "svg-cadastre.zip": "/images/svg-cadastre-small.png",

        "png-google.zip": "/images/svg-google-small.png",
        "png-osm.zip": "/images/svg-osm-small.png",
        "png-hiking.zip": "/images/svg-hiking-small.png",
        "png-urbanight.zip": "/images/svg-urbanight-small.png",
        "png-wireframe.zip": "/images/svg-wireframe-small.png",
        "png-cadastre.zip": "/images/svg-cadastre-small.png",

        "opl.xz": "/images/opl.png",
        "geojson.xz": "/images/geojson.png",
        "geojsonseq.xz": "/images/geojson.png",
        "text.xz": "/images/text.png",
        "sqlite.xz": "/images/sqlite.png",

        "mbtiles-basic.zip": "/images/svg-google-small.png",
        "mbtiles-openmaptiles.zip": "/images/svg-google-small.png",

        "csv.xz": "/images/csv.png",
        "csv.gz": "/images/csv.png",
        "shp.zip": "/images/shp-small.png",

        "osm.gz": "/images/osm.png",
        "osm.xz": "/images/osm.png",
        "osm.bz2": "/images/osm.png",

        "o5m.xz": "/images/o5m.png",
        "o5m.gz": "/images/o5m.png",

        "osm.pbf": "/images/pbf.png",

        "srtm-europe.osm.pbf": "/images/pbf.png",
        "srtm-europe.osm.xz": "/images/osm.png",

        "srtm.osm.pbf": "/images/pbf.png",
        "srtm.osm.xz": "/images/osm.png",

        "mapsforge-osm.zip": "/images/mapsforge-small.png",
        "mapsme-osm.zip": "/images/mapsme-small.png",
        "navit.zip": "/images/navit-small.png",
        "bbbike-perltk.zip": "/images/navit-small.png",
        "obf.zip": "/images/osmand-small.png",

        "srtm-europe.garmin-srtm.zip": "/images/garmin-srtm-800.png",
        "srtm.garmin-srtm.zip": "/images/garmin-srtm-1200.png",

        "srtm-europe.obf.zip": "/images/osmand-lago-contours-small.png",
        "srtm.obf.zip": "/images/osmand-lago-contours-small.png"
    },
    display_format_image: true,
    display_format_time: 7,

    // standard extract time in seconds for PBF
    // for a full planet.osm.pbf without metadata (33GB), it takes ca. 13min
    extract_time: 60 * 13,

    // display messages in browser console
    debug: 1,

    // extract-pro service with meta data and daily updates
    extract_pro: 0,

    // size of box in relation to the map
    "default_box_size": 0.66,

    "id_coord": ["#sw_lng", "#sw_lat", "#ne_lng", "#ne_lat"],
    "color_normal": "white",
    "color_error": "red",

    // ??
    "polygon_rotate": true,

    // nominatim address search
    search: {
        type: 'nominatim',
        max_zoom: 15,
        show_marker: true,
        viewbox: true,
        limit: 25,
        marker_permalink: false,
        marker_input_field: "city",
        user_agent: "extract.bbbike.org",
        paging: 5
    },

    // enable intro.js
    introjs: true,

    // not used yet
    "dummy": ""
};

// global variables
var state = {
    box: 0,
    /* 0: none, 1: box, 2: polygon, 3: polygon back or permalink */
    polygon: {}
};

// Initialise the 'map' object
var map;

// polygon & rectangle variables
var vectors;

// Sic! IE8 has no console.log()
var console;

////////////////////////////////////////////////////////////////////////////////
// main function after page load
//

function init() {
    var opt = {};

    // submit button is by default off until we created the boundary box
    $("input#submit").hide();

    initKeyPress();
    init_map_resize();
    map = init_map();

    extract_init_pro(opt);
    extract_init(opt);
    polygon_init();

    // old extract from permalink or back button
    if (check_lnglat_form(true)) {
        plot_polygon_back();
    } else {
        // start from scratch
        move_map_to_city();
    }

    // show either 'Select a different area' or the 'click here' message
    $("#drag_box_default").click(plot_default_box);
    $("#drag_box_select").click(plot_default_box_menu_off);

    permalink_init();
    if (config.open_infopage) open_infopage();
}

function move_map_to_city() {
    // default city Berlin
    var c = select_city();

    var sw_lng = c.sw[0];
    var sw_lat = c.sw[1];
    var ne_lng = c.ne[0];
    var ne_lat = c.ne[1];

    center_city(sw_lng, sw_lat, ne_lng, ne_lat);
}

function plot_polygon_back() {
    debug("plot polygon back");
    state.box = 3;

    var sw_lng = $("#sw_lng").val();
    var sw_lat = $("#sw_lat").val();
    var ne_lng = $("#ne_lng").val();
    var ne_lat = $("#ne_lat").val();
    var coords = $("#coords").val();

    if (coords == "0,0,0") { // to long URL, ignore
        coords = "";
    }
    debug("get coords from back button: " + coords);

    center_city(sw_lng, sw_lat, ne_lng, ne_lat);

    var polygon = coords ? string2coords(coords) : rectangle2polygon(sw_lng, sw_lat, ne_lng, ne_lat);
    var feature = plot_polygon(polygon);
    vectors.addFeatures(feature);

    // re-calculate polygon size
    state.func_serialize(feature);

    validateControls();
    plot_default_box_menu_on();
}

function center_city(sw_lng, sw_lat, ne_lng, ne_lat) {
    debug("center city: " + sw_lng + "," + sw_lat + " " + ne_lng + "," + ne_lat);

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var bounds = new OpenLayers.Bounds(sw_lng, sw_lat, ne_lng, ne_lat);

    bounds.transform(epsg4326, map.getProjectionObject());
    map.zoomToExtent(bounds);
}

function init_map() {
    var keyboard = new OpenLayers.Control.KeyboardDefaults({}); // "observeElement": $("#map")} );
    // var keyboard = new OpenLayers.Control.KeyboardDefaults({"observeElement": "map"});
    var map = new OpenLayers.Map("map", {
        controls: [
        new OpenLayers.Control.Navigation(), new OpenLayers.Control.PanZoomBar(), new OpenLayers.Control.ScaleLine({
            geodesic: true
        }), new OpenLayers.Control.MousePosition(), new OpenLayers.Control.Attribution(), new OpenLayers.Control.LayerSwitcher(), keyboard],

        maxExtent: new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34),
        maxResolution: 156543.0339,
        numZoomLevels: 19,
        units: 'm',
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326")
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

    map.addLayer(new OpenLayers.Layer.OSM("OSM CycleMap", ["https://a.tile.thunderforest.com/cycle/${z}/${x}/${y}@2x.png?apikey=6170aad10dfd42a38d4d8c709a536f38", "https://b.tile.thunderforest.com/cycle/${z}/${x}/${y}@2x.png?apikey=6170aad10dfd42a38d4d8c709a536f38"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        attribution: '<a href="https://www.OpenStreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>, <a href="https://www.opencyclemap.org/">(&copy) OpenCycleMap</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Mapbox Satellite", ["https://d.tiles.mapbox.com/v3/tmcw.map-j5fsp01s/${z}/${x}/${y}.png"], {
        attribution: '<a href="https://www.mapbox.com/">(&copy) mapbox</a>',
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 20
    }));


    // Bing roads and Satellite/Hybrid
    // disabled due wrong billing
    // add_bing_maps(map);
    state.map = map;
    return map;
}

function add_bing_maps(map) {
    var BingApiKey = "Aoz29UA0N53MbZ8SejgNnWib-_gW-JgHNwsSh77gzBZAyqEVRiJqRJ4ddJ5PXLXY";

    map.addLayer(new OpenLayers.Layer.Bing(
    // XXX: bing.com returns a wrong zoom level in JSON API call
    OpenLayers.Util.extend({
        initLayer: function () {
            // pretend we have a zoomMin of 0
            this.metadata.resourceSets[0].resources[0].zoomMin = 0;
            OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
        }
    }, {
        key: BingApiKey,
        type: "Road"
        //,  metadataParams: { mapVersion: "v1" }
    })));

    map.addLayer(new OpenLayers.Layer.Bing(OpenLayers.Util.extend({
        initLayer: function () {
            this.metadata.resourceSets[0].resources[0].zoomMin = 0;
            OpenLayers.Layer.Bing.prototype.initLayer.apply(this, arguments);
        }
    }, {
        key: BingApiKey,
        type: "AerialWithLabels",
        name: "Bing Hybrid",
        numZoomLevels: 18
    })));
}


// open info page at startup, but display it only once for the user

function open_infopage() {
    var oi_html = $("input#oi").val();
    var oi_cookie = jQuery.cookie("oi");

    if (oi_html == 0 && !oi_cookie) {
        debug("will open info page at startup");

        jQuery.cookie("oi", 1, {
            expires: 7
        });
        $("span#tools-help a").trigger("click");
    } else {
        debug("do not open info page again. html: " + oi_html + ", cookie: " + oi_cookie);
    }

    $("input#oi").val("1");
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
        }, 0);
    });
}

function string2coords(coords) {
    var list = [];
    if (!coords) return list;
    var _list = coords.split("|");
    for (var i = 0; i < _list.length; i++) {
        var pos = _list[i].split(",");
        list.push(pos);
    }
    return list;
}

/* create a polygon based on a points list, which can be added to a vector */

function plot_polygon(poly) {
    debug("plot polygon, length: " + poly.length);

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var points = [];
    for (var i = 0; i < poly.length; i++) {
        var point = new OpenLayers.Geometry.Point(poly[i][0], poly[i][1]);
        point.transform(epsg4326, map.getProjectionObject());
        points.push(point);
    }

    var linear_ring = new OpenLayers.Geometry.LinearRing(points);
    var polygonFeature = new OpenLayers.Feature.Vector(new OpenLayers.Geometry.Polygon(linear_ring));

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

// override standard OpenLayers permalink method

function permalink_init() {
    debug("permalink init");

    OpenLayers.Control.Permalink.prototype.createParams = function (center, zoom, layers) {
        var params = OpenLayers.Util.getParameters(this.base);

        // not needed
        delete params.lat;
        delete params.lon;
        delete params.zoom;

        params.lang = $("span#active_language").text();

        params.sw_lng = $("#sw_lng").val();
        params.sw_lat = $("#sw_lat").val();
        params.ne_lng = $("#ne_lng").val();
        params.ne_lat = $("#ne_lat").val();
        params.format = $("select[name=format] option:selected").val();

        params.oi = $("#oi").val();
        if (!params.oi) delete params.oi;
        params.city = $("#city").val();
        if (!params.city) delete params.city;
        params.coords = $("#coords").val(); // polygon
        if (!params.coords) delete params.coords;

        //layers
        layers = layers || map.layers;
        params.layers = '';
        for (var i = 0, len = layers.length; i < len; i++) {
            var layer = layers[i];

            if (layer.isBaseLayer) {
                params.layers += (layer == map.baseLayer) ? "B" : "0";
            } else {
                params.layers += (layer.getVisibility()) ? "T" : "F";
            }
        }

        // keep copy for submit
        $("#layers").attr("value", params.layers);

        return params;
    };

    // wait a moment for inital permalink, to read values from forms
    var permalink = new OpenLayers.Control.Permalink('permalink');
    state.permalink = permalink;

    map.addControl(permalink);
}


function extract_init(opt) {
    var box;
    var transform;
    var markerLayer;
    var markerControl;

    // main vector
    vectors = new OpenLayers.Layer.Vector("Vector Layer", {
        displayInLayerSwitcher: false
    });
    map.addLayer(vectors);

    // start with a rectangle first
    box = new OpenLayers.Control.DrawFeature(vectors, OpenLayers.Handler.RegularPolygon, {
        handlerOptions: {
            sides: 4,
            snapAngle: 90,
            irregular: true,
            persist: true
        }
    });

    // box.handler.callbacks.done = endDrag;
    map.addControl(box);

    // resize retangle, but not rotate or add points
    transform = new OpenLayers.Control.TransformFeature(vectors, {
        rotate: false,
        irregular: true
    });
    transform.events.register("transformcomplete", transform, transformComplete);
    state.transform = transform;

    map.addControl(transform);

    // moving the map top/bottom/left/right
    map.events.register("moveend", map, mapMoved);

    $("#ne_lat").change(boundsChanged);
    $("#sw_lng").change(boundsChanged);
    $("#ne_lng").change(boundsChanged);
    $("#sw_lat").change(boundsChanged);
    $("#city").change(updatePermalink);

    setBounds(map.getExtent());

    if ($("select#format").length) {
        $("select#format").change(function () {
            validateControls();
            updatePermalink();
            if (config.display_format_image) display_format_image();
        });

        // !!! Firefox only !!
        // The select element is a UI object, not a HTML object and will not
        // fire events except on Firefox
        var display_format_image_timer;
        $("select#format").on("keyup mouseover", function (e) {
            validateControls();
            // debug("got event: " + e.type);
            if (config.display_format_image) {
                if (display_format_image_timer) clearTimeout(display_format_image_timer);
                display_format_image_timer = setTimeout(function () {
                    display_format_image()
                }, 200);
            }
        });
    }

    state.proj4326 = new OpenLayers.Projection('EPSG:4326');

    // run at startup
    if (config.display_format_image) display_format_image();
}

function boundsChanged() {
    debug("boundsChanged");

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");

    if (!check_lnglat_form()) {
        alert(M("value is out of range: lng -180 ... 180, lat -90 .. 90"));
        return;
    }

    var bounds = new OpenLayers.Bounds($("#sw_lng").val(), $("#sw_lat").val(), $("#ne_lng").val(), $("#ne_lat").val());

    bounds.transform(epsg4326, map.getProjectionObject());

    map.events.unregister("moveend", map, mapMoved);
    map.zoomToExtent(bounds);

    clearBox();
    drawBox(bounds);
    validateControls();
    mapnikSizeChanged();
}

function clearBox() {
    debug("clearBox");

    state.transform.deactivate();
    vectors.destroyFeatures();

    // reset hidden variables
    $("#coords").attr("value", "");
    $("#as").attr("value", "");
    $("#pg").attr("value", "");

    // reset visible skm / filesize / time estimates
    $("#square_km_small").html("");
    $("#size_small").html("");
    $("#time_small").html("");

    // reset warnings
    $("#export_osm_too_large").hide();


    state.polygon.area = 0;
    state.box = 0;

}


function drawBox(bounds) {
    debug("drawBox");
    state.box = 1;

    var feature = new OpenLayers.Feature.Vector(bounds.toGeometry());
    vectors.addFeatures(feature);
}

function transformComplete(event) {
    setBounds(event.feature.geometry.bounds);
    validateControls();
}

function mapMoved() {
    debug("mapMoved");
    if (state.box == 0) {
        setBounds(map.getExtent());
        validateControls();
    }
    updateMClink();
}

function mapnikSizeChanged() {
    var size = mapnikImageSize($("#mapnik_scale").val());

    $("#mapnik_image_width").html(size.w);
    $("#mapnik_image_height").html(size.h);

    validateControls();
}

/*
 * set the bounds box values (sw, ne) by a given box
 *
 */
function setBounds(bounds) {
    debug("setBounds");
    // debug(arguments.callee.caller);
    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var decimals = Math.pow(10, Math.floor(map.getZoom() / 3));

    // box not set yet
    if (!bounds) return;

    bounds = bounds.clone().transform(map.getProjectionObject(), epsg4326);

    function v(value) {
        var val = Math.round(value * decimals) / decimals;
        if (val < -180) {
            val += 360;
        } else if (val > 180) {
            val -= 360;
        }

        return val;
    }

    $("#sw_lng").val(v(bounds.left));
    $("#sw_lat").val(v(bounds.bottom));
    $("#ne_lng").val(v(bounds.right));
    $("#ne_lat").val(v(bounds.top));
    debug("set bounds box: " + bounds.left + "," + bounds.bottom + " " + bounds.right + "," + bounds.top)

    mapnikSizeChanged();
}

// extract-pro service can extract larger areas

function extract_init_pro(opt) {
    var hostname = $(location).attr('hostname');
    if (hostname.match(/^extract-pro[1-9]?\.bbbike\.org/i) || $(location).attr('search').match(/[\?&;]pro=[\w]+/)) {
        debug("enable BBBike Pro service");

        config.max_size["default"] *= 1.7;
        config.max_size["osm.pbf"] *= 6;
        config.max_size["shp.zip"] *= 4;
        config.max_skm *= 2;

        config.extract_pro = 1;
    }
}

// return javascript float coordinates

function cf(name) {
    var val = $("#" + name).val();
    return parseFloat(val);
}

function plot_default_box() {
    debug("plot default box");


    // reset to full map
    setBounds(map.getExtent());
    validateControls();

    if (!check_lnglat_form()) {
        alert(M("lng or lat value is out of range -180 ... 180, -90 .. 90"));
        return;
    }


    var sw_lng = cf("sw_lng");
    var sw_lat = cf("sw_lat");
    var ne_lng = cf("ne_lng");
    var ne_lat = cf("ne_lat");

    debug("map box: " + sw_lng + "," + sw_lat + " " + ne_lng + "," + ne_lat);

    // draw a smaller box than the map, by config default_box_size
    if (config.default_box_size > 0 && config.default_box_size < 1) {
        debug("default box factor: " + config.default_box_size);
        var lng = ne_lng - sw_lng;
        var lat = ne_lat - sw_lat;
        var factor = (1 - config.default_box_size) / 2;

        debug("lng: " + lng * factor + " " + lat * factor + " " + factor);

        sw_lng += lng * factor;
        sw_lat += lat * factor;

        ne_lng -= lng * factor;
        ne_lat -= lat * factor;

        debug("default box: " + sw_lng + "," + sw_lat + " " + ne_lng + "," + ne_lat);
    }

    state.box = 1;
    var polygon = rectangle2polygon(sw_lng, sw_lat, ne_lng, ne_lat);
    var feature = plot_polygon(polygon);
    vectors.addFeatures(feature);

    setBounds(feature.geometry.bounds);
    plot_default_box_menu_on();
    // setBounds(map.getExtent());
    $("input#submit").show();
}

function introjs_start() {
    if (!config.introjs) {
        debug("introjs is disabled");
        return;
    }

    // fire intro.js    
    introJs().setOption('showProgress', true).start();
    //dialog_close();
}

// hide the help popup if open

function dialog_close() {
    if ($(".dialog-close")) {
        $(".dialog-close").click();
    }
}

function plot_default_box_menu_on() {
    $("input#submit").show();

    polygon_menu(true); // display poygon menu
    polygon_update();
    // switch menu
    $("#drag_box_default").hide();
    $("#drag_box_select").show();
    $("#start_default_box").attr('checked', false);

    if (config.introjs) {
        if ($(".introjs-donebutton")) {
            $(".introjs-donebutton").click();
        }

        dialog_close();
    }
}

// remove default box from map

function plot_default_box_menu_off() {
    // no submit button before we created a bounding box with click 'here'
    $("input#submit").hide();

    // $("#drag_box_select_reset").attr('checked', false);
    $("#drag_box_default").show();
    $("#drag_box_select").hide();

    polygon_menu(false);
    clearBox();
    setMapHeight();
}

// called from HTML page

function polygon_update() {
    return state.update()
};

/* 240000 -> 240,000 */

function large_int(number) {
    number = Math.round(number);

    var string = String(number);

    if (number < 1000) {
        return number;
    } else {
        return string.slice(0, -3) + "," + string.substring(-3, 3);
    }
}

/* validate lat or lng values */

function check_lat(number) {
    return check_coord(number, 90)
}

function check_lng(number) {
    return check_coord(number, 180)
}

function check_coord(number, max) {
    if (number == NaN || number == "") return false;
    if (number >= -max && number <= max) return true;

    return false;
}

function checkform() {
    var ret = 0;
    var color_normal = "white";
    var color_error = "red";


    var inputs = $("form#extract input"); // debug("inputs elements: " + inputs.length); return false;
    for (var i = 0; i < inputs.length; ++i) {
        var e = inputs[i];


        if (e.value == "") {
            // ignore hidden input fields for check, e.g. "coords"
            if (e.type == "hidden") continue;

            // check only named input fields
            if (e.name == "") continue;

            // optional forms fields
            if (config.city_name_optional && e.name == "city") continue;

            e.style.background = color_error;
            e.focus();
            ret = 1;
            continue;
        }

        // catch email addresses in city name - a typical user mistake
        if (config.city_name_check && e.name == "city") {
            if (e.value && e.value.match(/\w+@.+\.\w+$/)) {
                $("input#city").val("");
                e.style.background = color_error;
                ret = 5;
                continue;
            }
        }

        if (e.name == "sw_lat" || e.name == "sw_lng" || e.name == "ne_lat" || e.name == "ne_lng") {
            if (e.name.match(/_lat/) ? !check_lat(e.value) : !check_lng(e.value)) {
                e.style.background = color_error;
                ret = 1;
                continue;
            }
        }

        // check area size in MB
        if (e.name == "as") {
            var format = $("select[name=format] option:selected").val();
            var max_size = config.max_size[format] ? config.max_size[format] : config.max_size["default"];

            debug("selected format: " + format + " max_size: " + max_size);
            if (e.value < 0 || e.value > max_size) {
                ret = 2;
            }
        }

        // reset color
        e.style.background = color_normal;
    }

    if (state.box == 0) {
        alert(M("Please create a bounding box first!"));
        ret = 3;
    } else if (ret > 0) {
        alert(ret == 1 ? M("Please fill out all fields!") : ret == 5 ? M("Please do not use an email address as name, it will be public") : M("Please use a smaller area! Max size: ") + max_size + "MB");
    } else if (config.box_on_map) {
        if (!validate_box_on_map()) {
            alert(M("The bounding box is outside of the map. Please move back to the box, or >>Select a different<< area on the map"));
            ret = 4;
        }
    }

    return ret == 0 ? true : false;
}


function check_lnglat_form(noerror) {
    var ret = true;
    var coord = config.id_coord;

    for (var i = 0; i < coord.length; i++) {
        var val = $(coord[i]).val();
        if (coord[i].match(/_lng$/) ? check_lng(val) : check_lat(val)) {
            $(coord[i]).css("background", config.color_normal);
        } else {
            if (!noerror) $(coord[i]).css("background", config.color_error);
            ret = false;
            // debug("check_lnglat_form: " + coord[i] + " " + val);
        }
    }

    debug("check_lnglat_form: " + ret);
    return ret;
}

// write to JS console or debug tag
// keep time state for debugging
state.debug_time = {
    "start": $.now(),
    "last": $.now()
};

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
    console.log("BBBike extract: " + timestamp + state.box + " " + text);

    // no debug on html page
    if (config.debug <= 1) return;

    if (!id) id = "debug";

    var tag = $("#" + id);
    if (!tag) return;

    // log to HTML page
    tag.html(timestamp + text);
}

// check browser window height, and re-adjust sidebar and map size

function setMapHeight() {
    var height = $(window).height();
    var width = $(window).width() - $('#sidebar_left').width();
    if (height < 200) height = 200;

    // $('#content').height(height);
    // $('#content').width(width);
    width = Math.floor(width);
    height = Math.floor(height);

    $('#map').width(width);
    $('#map').height(height);

    debug("setMapHeight: " + $(window).height() + " " + $(window).width());

    // hide help messages on small screens
    if ($(window).height() < 480) {
        setTimeout(function () {
            $(".normalscreen").hide()
        }, 1500);
    } else {
        setTimeout(function () {
            $(".normalscreen").show()
        }, 250);
    }

    validateControls();
    // permalink_init();
};

/*
 * geo location
 *
 */
function locateMe() {
    if (!navigator || !navigator.geolocation) return;

    var tag = locateMe_tag();
    if (tag) {
        tag.show();
        navigator.geolocation.getCurrentPosition(locateMe_cb, locateMe_error);
        setTimeout(function () {
            tag.hide();
        }, 5000); // paranoid
    }
}

function locateMe_tag() {
    return $("#tools-pageload");
}

function setStartPos(lon, lat, zoom) {
    var lonlat = new OpenLayers.LonLat(lon, lat);
    var proj4326 = new OpenLayers.Projection('EPSG:4326');

    var center = lonlat.clone();
    center.transform(proj4326, map.getProjectionObject());
    map.setCenter(center, zoom);
}

function locateMe_cb(pos) {
    setStartPos(pos.coords.longitude, pos.coords.latitude, 10);
    locateMe_tag().hide();
    debug("set position: " + pos.lat + "," + pos.lon);
}

function locateMe_error(error) {
    debug("could not found position");
    locateMe_tag().hide();
    return;
}

function google_plusone() {
    $.getScript('https://apis.google.com/js/plusone.js');
    $('.gplus').remove();
}


/*
  here are dragons!
  code copied from js/OpenLayers-2.11/OpenLayers.js: OpenLayers.Control.KeyboardDefaults

  see also: http://www.mediaevent.de/javascript/Extras-Javascript-Keycodes.html
*/
function initKeyPress() {
    // move all maps left/right/top/down

    function moveMap(direction, option) {
        var animate = false;

        map.pan(direction, option, {
            animate: animate
        });
    };

    // OpenLayers.Control.KeyboardDefaults.observeElement = $("#map");
    OpenLayers.Control.KeyboardDefaults.prototype.defaultKeyPress = function (evt) {
        // ignore key events while in forms
        if (forms_focus()) {
            return;
        }

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

            // '+', '=''
        case 43:
        case 61:
        case 187:
        case 107:
            this.map.zoomIn();
            break;

            // '-'
        case 45:
        case 109:
        case 189:
        case 95:
            this.map.zoomOut();
            break;

        case 71:
            // 'g'
            locateMe();
            break;
        }
    };
};

/*
 * show/hide polygon menu for rotate/resize
 *
 */
function polygon_menu(enabled) {
    enabled ? $("#polygon_controls").show() : $("#polygon_controls").hide();

    // always start menu with polygon vertices
    $("#createVertices").removeAttr("checked");
    $("#rotate").removeAttr("checked");

    config.polygon_rotate ? $("#rotate").attr("checked", "checked") : $("#createVertices").attr("checked", "checked");
}

/*
 * select an area to display on the map
 */
function select_city(name) {
    var city = {
        "Berlin": {
            "sw": [12.875, 52.329],
            "ne": [13.902, 52.705]
        }
    }

    if (name && city[name]) {
        return city[name];
    }

    var key;
    var list = new Array;
    for (key in city) {
        list.push(key);
    }

    key = list[parseInt(Math.random() * list.length)];
    return city[key];
}

function updatePermalink() {
    if (state.permalink) {
        debug("updatePermalink");
        state.permalink.updateLink();
    }

    updateMClink();
}

function updateMClink() {
    var mc_link = $('#mc_link');

    // no map compare link in HTML?    
    if (!mc_link || mc_link.length == 0) {
        return;
    }
    var url = getMCLink(mc_link.attr("href"));

    mc_link.attr("href", url);

    return url;
}

function getMCLink(href) {
    var center = map.getCenter().transform(map.getProjectionObject(), state.proj4326)
    var zoom = map.getZoom();

    // full base URL, without parameters
    var base = href;
    if (base.indexOf("?") != -1) {
        base = base.substring(0, base.indexOf("?"));
    }

    // bbbike.org/mc/#map=5/51.509/-5.603    
    if (base.indexOf("#") != -1) {
        debug("cleanup '#' in url: " + base);
        base = base.substring(0, base.indexOf("#"));
    }

    var url = base + '?lon=' + center.lon + '&lat=' + center.lat + '&zoom=' + zoom + "&profile=extract" + "&source=extract";

    return url;
}


function show_skm(skm, filesize) {
    var format = filesize.format;
    var max_skm = config.max_skm_format[format] || config.max_skm;

    if ($("#square_km").length) {
        var html = "area covers " + large_int(skm) + " square km";
        if (config.show_filesize) {
            html += filesize.html;
            $("#square_km_small").html(large_int(skm) + " km<sup>2</sup>");
            var fs = filesize.size < 1 ? Math.round(filesize.size * 10) / 10 : Math.round(filesize.size);
            $("#size_small").html("~" + fs + " MB");
            $("#time_small").html(filesize.time + " min");
            // $("#square_km").html(html);
        }
    }

    // keep area size in forms
    var area_size = $("#as");
    if (area_size) {
        area_size.attr("value", filesize.size);
    }

    // by default, assume everything is inside the limit
    $("#export_osm_too_large").hide();

    if (skm > max_skm) {
        $("#size").html("Max area size: " + max_skm + "skm.");
        $("#export_osm_too_large").show();
    }

    // Osmand etc. works only for small areas less than 200MB
    if (config.max_size[format]) {
        if (filesize.size > config.max_size[format]) {
            $("#size").html("Max " + format + " file size: " + config.max_size[format] + " MB.");
            $("#export_osm_too_large").show();
        }
    } else if (filesize.size > config.max_size["default"]) {
        $("#size").html("Max default file size: " + config.max_size["default"] + " MB.");
        $("#export_osm_too_large").show();
    }

    updatePermalink();
}


// size of an area in square km

function square_km(x1, y1, x2, y2) { // SW x NE
    var height = OpenLayers.Util.distVincenty({
        lat: x1,
        lon: y1
    }, {
        lat: x1,
        lon: y2
    });
    var width = OpenLayers.Util.distVincenty({
        lat: x1,
        lon: y1
    }, {
        lat: x2,
        lon: y1
    });

    return (height * width);
}

function display_format_image() {
    var format = $("select#format option:selected").val();
    var format_text = $("select#format option:selected").text();

    var image = config.format_images[format] || "";
    debug("display format: " + format + ", image: " + image);

    if (!image) {
        $("#format_image").html("");
    } else {
        var text = '<div><p/><i>' + M('Extract format is') + ': ' + format_text + '</i></div>';
        $("#format_image").html('<div align="center">' + text + '<a target="_new" href="/extract-screenshots.html">' + '<img src="' + image + '"/>' + '</a></div>');

        // clear previous timeouts, always display images for 5 seconds
        if (state.display_timeout) {
            clearTimeout(state.display_timeout);
        }
        state.display_timeout = setTimeout(function () {
            $("#format_image").html("")
        }, config.display_format_time * 1000);
    }
}

function validateControls() {
    debug("validateControls state.box: " + state.box);

    if (state.box == 0) return;

    var bounds = new OpenLayers.Bounds($("#sw_lng").val(), $("#sw_lat").val(), $("#ne_lng").val(), $("#ne_lat").val());

    var skm = square_km($("#sw_lat").val(), $("#sw_lng").val(), $("#ne_lat").val(), $("#ne_lng").val());
    var format = $("select[name=format] option:selected").val();

    if (!state.polygon.area && $("#pg").val()) {
        debug("validateControls found polygon: " + $("#pg").val() + " as: " + $("#as").val());
    }

    //
    // polygon area in relation to the bounding rectangle box.
    // value: 0...1
    var polygon = state.polygon.area && skm > 0 ? (state.polygon.area / skm / 1000000) : 1;
    $("#pg").attr("value", polygon);

    var url = "/cgi/tile-size.cgi?format=" + format + "&lat_sw=" + $("#sw_lat").val() + "&lng_sw=" + $("#sw_lng").val() + "&lat_ne=" + $("#ne_lat").val() + "&lng_ne=" + $("#ne_lng").val();

    debug("validateControls frac: " + polygon + " skm: " + skm);

    debug("polygon is on map: " + validate_box_on_map());

    // plot area size and file size
    $.getJSON(url, function (data) {
        var size = data.size
        var error = 5000000;
        if (size == 'undefined' || size < 0) {
            debug("error in tile size: " + size + ", reset to " + error);
            size = error;
        }

        // adjust polygon size for huge data, the area size is usually not normal (e.g. sea coast)
        if (size > 50000) {
            // min. size factor 0.3 or 0.5 for very large areas
            var p = polygon + (1 - polygon) * (size > 200000 ? 0.7 : 0.3);
            debug("reset polygon of size: " + size + "skm to: " + (size * p) + " skm from polygon: " + polygon + " to: " + p);
            polygon = p;
        }

        var sub_planet_factor = data.sub_planet_size / data.planet_size;
        var filesize = show_filesize(skm * polygon, size * polygon, sub_planet_factor);
        show_skm(skm * polygon, filesize);
    });
}

function validate_box_on_map() {
    debug("check if bounding box is on map: state.box: " + state.box);
    if (state.box == 0) return 0;

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var bounds = map.getExtent();
    bounds.transform(map.getProjectionObject(), epsg4326);

    if (bounds.contains($("#sw_lng").val(), $("#sw_lat").val()) || // left, bottom
    bounds.contains($("#ne_lng").val(), $("#ne_lat").val()) || // right, top
    bounds.contains($("#sw_lng").val(), $("#ne_lat").val()) || // left, top
    bounds.contains($("#ne_lng").val(), $("#sw_lat").val()) // right, bottom
    ) {
        debug("box is on map");
        return 1;
    }

    return 0;
}

function show_filesize(skm, real_size, sub_planet_factor) {
    var extract_time = config.extract_time || 900; // standard extract time in seconds for PBF
    var format = $("select[name=format] option:selected").val();
    var size = real_size ? real_size / 1024 : 0;
    debug("show filesize skm: " + parseInt(skm) + " size: " + Math.round(size) + "MB " + format + " sub planet factor: " + sub_planet_factor);

    // all formats *must* be configured
    // Note: the size is based on the created output format, and *not* of the input *.pbf
    var filesize = {
        "osm.pbf": {
            "size": 1,
            "time": 1
        },
        "osm.gz": {
            "size": 2,
            "time": 0.5
        },
        "osm.bz2": {
            "size": 1.5
        },
        "osm.xz": {
            "size": 1.8,
            "time": 0.4
        },
        "garmin-osm.zip": {
            "size": 0.8,
            "time": 3
        },
        "garmin-osm-ascii.zip": {
            "size": 0.67,
            "time": 3
        },
        "garmin-osm-latin1.zip": {
            "size": 0.67,
            "time": 3
        },
        "garmin-cycle.zip": {
            "size": 0.4,
            "time": 3
        },
        "garmin-cycle-ascii.zip": {
            "size": 0.4,
            "time": 3
        },
        "garmin-cycle-latin1.zip": {
            "size": 0.4,
            "time": 3
        },
        "garmin-leisure.zip": {
            "size": 0.75,
            "time": 4
        },
        "garmin-leisure-ascii.zip": {
            "size": 0.75,
            "time": 4
        },
        "garmin-leisure-latin1.zip": {
            "size": 0.75,
            "time": 4
        },
        "garmin-bbbike.zip": {
            "size": 0.55,
            "time": 4
        },
        "garmin-bbbike-ascii.zip": {
            "size": 0.55,
            "time": 4
        },
        "garmin-bbbike-latin1.zip": {
            "size": 0.55,
            "time": 4
        },
        "garmin-onroad.zip": {
            "size": 0.07,
            "time": 22
        },
        "garmin-onroad-ascii.zip": {
            "size": 0.07,
            "time": 22
        },
        "garmin-onroad-latin1.zip": {
            "size": 0.07,
            "time": 22
        },
        "garmin-ontrail.zip": {
            "size": 0.14,
            "time": 20
        },
        "garmin-ontrail-ascii.zip": {
            "size": 0.14,
            "time": 20
        },
        "garmin-ontrail-latin1.zip": {
            "size": 0.14,
            "time": 20
        },
        "garmin-opentopo.zip": {
            "size": 0.7,
            "time": 3.5
        },
        "garmin-opentopo-ascii.zip": {
            "size": 0.7,
            "time": 3.5
        },
        "garmin-opentopo-latin1.zip": {
            "size": 0.7,
            "time": 3.5
        },
        "garmin-openfietslite.zip": {
            "size": 0.6,
            "time": 4.5
        },
        "garmin-openfietslite-ascii.zip": {
            "size": 0.6,
            "time": 4.5
        },
        "garmin-openfietslite-latin1.zip": {
            "size": 0.6,
            "time": 5.5
        },
        "garmin-openfietsfull.zip": {
            "size": 0.8,
            "time": 5.5
        },
        "garmin-openfietsfull-ascii.zip": {
            "size": 0.8,
            "time": 4.5
        },
        "garmin-openfietsfull-latin1.zip": {
            "size": 0.8,
            "time": 5.5
        },
        "garmin-oseam.zip": {
            "size": 0.64,
            "time": 4
        },
        "garmin-oseam-ascii.zip": {
            "size": 0.64,
            "time": 4
        },
        "garmin-oseam-latin1.zip": {
            "size": 0.64,
            "time": 4
        },
        "png-google.zip": {
            "size": 0.7,
            "time": 10
        },
        "png-osm.zip": {
            "size": 0.7,
            "time": 10
        },
        "png-hiking.zip": {
            "size": 0.7,
            "time": 10
        },
        "png-urbanight.zip": {
            "size": 0.7,
            "time": 10
        },
        "png-wireframe.zip": {
            "size": 0.7,
            "time": 10
        },
        "png-cadastre.zip": {
            "size": 0.7,
            "time": 10
        },
        "svg-google.zip": {
            "size": 0.7,
            "time": 10
        },
        "svg-osm.zip": {
            "size": 0.7,
            "time": 10
        },
        "svg-hiking.zip": {
            "size": 0.7,
            "time": 10
        },
        "svg-urbanight.zip": {
            "size": 0.7,
            "time": 10
        },
        "svg-wireframe.zip": {
            "size": 0.7,
            "time": 10
        },
        "svg-cadastre.zip": {
            "size": 0.7,
            "time": 10
        },

        "shp.zip": {
            "size": 2,
            "time": 1
        },
        "obf.zip": {
            "size": 1.4,
            "time": 10
        },
        "o5m.gz": {
            "size": 1.04
        },
        "o5m.xz": {
            "size": 0.94
        },
        "o5m.bz2": {
            "size": 0.88
        },
        "csv.gz": {
            "size": 1
        },
        "csv.xz": {
            "size": 0.50
        },
        "csv.bz2": {
            "size": 0.80,
            "time": 1.2
        },
        "opl.xz": {
            "size": 1.70
        },
        "geojson.xz": {
            "size": 1.98
        },
        "geojsonseq.xz": {
            "size": 1.97
        },
        "text.xz": {
            "size": 1.80
        },
        "sqlite.xz": {
            "size": 1.50
        },
        "mbtiles-basic.zip": {
            "size": 0.48,
            "time": 1.5
        },
        "mbtiles-openmaptiles.zip": {
            "size": 0.75,
            "time": 2
        },
        "mapsforge-osm.zip": {
            "size": 0.7,
            "time": 8
        },
        "mapsme-osm.zip": {
            "size": 0.85,
            "time": 2
        },
        "navit.zip": {
            "size": 0.8,
            "time": 1.5
        },
        "bbbike-perltk.zip": {
            "time": 90,
            "size": 2.2
        },
        "srtm-europe.osm.pbf": {
            "planet": 0.3,
            "size": 1,
            "time": 0.2
        },
        "srtm-europe.osm.xz": {
            "planet": 0.3,
            "size": 1.8,
            "time": 0.2
        },
        "srtm-europe.garmin-srtm.zip": {
            "planet": 0.3,
            "size": 1.3,
            "time": 0.3
        },
        "srtm-europe.obf.zip": {
            "planet": 0.3,
            "size": 2.0,
            "time": 0.5
        },
        "srtm.osm.pbf": {
            "size": 1,
            "time": 1
        },
        "srtm.osm.xz": {
            "size": 1.8,
            "time": 1
        },
        "srtm.garmin-srtm.zip": {
            "size": 1.3,
            "time": 2
        },
        "srtm.obf.zip": {
            "size": 2.0,
            "time": 10
        }
    };

    if (!filesize[format]) {
        debug("Unknown format: '" + format + "'");
    }

    var factor = filesize[format].size ? filesize[format].size : 1;

    var factor_time = filesize[format].time ? filesize[format].time : 1;
    var extract_time_min = extract_time * (filesize[format].planet ? filesize[format].planet : 1);

    // sub planets are much faster to extract
    if (sub_planet_factor) {
        extract_time_min *= sub_planet_factor;
    }

    var time_min = extract_time_min + (0.15 * size * factor_time);
    var time_max = extract_time_min + (0.30 * size * factor_time);

    var html = ", ~" + Math.round(size * 10) / 10 + "MB"; //  + format + " data";
    var time = "";
    if (skm < config.max_skm) {
        var min = Math.ceil(time_min / 60);
        var max = Math.ceil(time_max / 60);
        time = min + (min != max ? "-" + max : "");
        html += ", approx. extract time: " + time + " minutes";
    }

    var obj = {
        "html": html,
        // text message
        "size": size,
        // size in MB
        "time": time,
        // time in minutes
        "format": format
    };

    return obj;
}

function osm_round(number) {
    return parseInt(number * 1000 + 0.5) / 1000;
}

function mapnikImageSize(scale) {
    var bounds = new OpenLayers.Bounds($("#sw_lng").val(), $("#sw_lat").val(), $("#ne_lng").val(), $("#ne_lat").val());
    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var epsg900913 = new OpenLayers.Projection("EPSG:900913");

    bounds.transform(epsg4326, epsg900913);

    return new OpenLayers.Size(Math.round(bounds.getWidth() / scale / 0.00028), Math.round(bounds.getHeight() / scale / 0.00028));
}

/*
 * configure and initialise polygon objects and events
 *
 */
function polygon_init() {
    var controls;

    OpenLayers.Feature.Vector.style['default']['strokeWidth'] = '3';
    OpenLayers.Feature.Vector.style['default']['pointRadius'] = '14'; // huge points for tablets
    var renderer = OpenLayers.Layer.Vector.prototype.renderers;

    function report(event) {
        debug("report: " + event.type); // + " " + event.feature ? event.feature.id : event.components);
        if (event.feature) {
            if (event.type == "featuremodified" || event.type == "sketchcomplete") {
                serialize(event.feature);
            }
        }
    }

    vectors.onFeatureInsert = function () {
        debug("rectangle or polygon was created");
    }

    vectors.events.on({
        "beforefeaturemodified": report,
        "featuremodified": report,
        "afterfeaturemodified": report,
        "vertexmodified": report,
        "sketchmodified": report,
        "sketchstarted": report,
        "sketchcomplete": report
    });

    controls = {
        polygon: new OpenLayers.Control.DrawFeature(vectors, OpenLayers.Handler.Polygon),
        modify: new OpenLayers.Control.ModifyFeature(vectors)
    };

    for (var key in controls) {
        map.addControl(controls[key]);
    }

    function v(value) {
        return osm_round(value);
    };

    function serialize(obj) {
        debug("serialize");
        state.box = 2;

        var epsg4326 = new OpenLayers.Projection("EPSG:4326");

        // var bounds = obj.geometry.bounds.clone().transform(map.getProjectionObject(), epsg4326);
        var feature = obj.clone(); // work on a clone
        feature.geometry.transform(map.getProjectionObject(), epsg4326);
        feature.geometry.calculateBounds();
        var bounds = feature.geometry.bounds;

        var vec = feature.geometry.getVertices();

        debug("serialize polygon len: " + vec.length);
        // Calculate the approximate area of the polygon were it projected onto the earth.
        var polygon_area = feature.geometry.getGeodesicArea();
        state.polygon.area = polygon_area;

        // store coords data in a hidden forms input field
        var coords = "";
        for (var i = 0; i < vec.length; i++) {
            if (i > 0) coords += '|';
            coords += v(vec[i].x) + "," + v(vec[i].y);
        }

        is_rectangle(vec, bounds) ? $("#coords").attr("value", "") : $("#coords").attr("value", coords);
        debug("is rec: " + is_rectangle(vec, bounds));

        if (bounds != null) {
            $("#sw_lng").val(v(bounds.left));
            $("#sw_lat").val(v(bounds.bottom));
            $("#ne_lng").val(v(bounds.right));
            $("#ne_lat").val(v(bounds.top));
            validateControls();
        }
    }
    state.func_serialize = serialize; // needs to be called from plot_polygon_back()
/*
    var options = {}; // hover: true, onSelect: serialize,
    var select = new OpenLayers.Control.SelectFeature(vectors, options);
    map.addControl(select);
    select.activate();
    */

    controls.modify.activate();

    // called from HTML page
    state.update = function update() {
        // reset modification mode
        controls.modify.mode = OpenLayers.Control.ModifyFeature.RESHAPE;
        var rotate = $("#rotate").attr("checked");

        // rotate, resize, move
        if (rotate) {
            // controls.modify.mode |= OpenLayers.Control.ModifyFeature.ROTATE;
            controls.modify.mode |= OpenLayers.Control.ModifyFeature.RESIZE;
            controls.modify.mode |= OpenLayers.Control.ModifyFeature.DRAG;

            controls.modify.mode &= ~OpenLayers.Control.ModifyFeature.RESHAPE;
        }

        // add new points
        controls.modify.createVertices = rotate ? false : true;
    }


    function is_rectangle(vec, bounds) {
        if (vec.length != 4) return false;

        if (
        v(bounds.left) == v(vec[0].x) && v(bounds.bottom) == v(vec[0].y) && v(bounds.right) == v(vec[1].x) && v(bounds.bottom) == v(vec[1].y) && v(bounds.right) == v(vec[2].x) && v(bounds.top) == v(vec[2].y) && v(bounds.left) == v(vec[3].x) && v(bounds.top) == v(vec[3].y)) {
            return true;
        }
        return false;
    }
}

function toggle_lnglatbox() {
    $('.lnglatbox').toggle();
    $('.lnglatbox_toggle').toggle();

    $('.uncheck').attr('checked', false);
}

// check if we have an active forms

function forms_focus() {
    var focus = jQuery(':focus');
    if (focus.attr('id')) {
        // focus.trigger("blur");
        debug("Extract focus is on form element: " + focus.attr('id'));
        return 1;
    }
}

/*
 * initialise jquery dialog helper windows
 *
 */
function init_dialog_window() {
    if (jQuery('#tools-helpwin').length == 0) return;

    jQuery('#tools-helpwin').jqm({
        ajax: '@href',
        trigger: 'a.tools-helptrigger, a.tools-helptrigger-small',
        overlay: 25,
        onLoad: function (hash) {
            hash.w.jqmAddClose('.dialog-close');

            // resize for smaller windows?
            if (jQuery(hash.t).attr('class') == 'tools-helptrigger-small') {
                hash.w.removeClass("jqmWindowLarge").addClass("jqmWindowSmall");
            } else {
                hash.w.removeClass("jqmWindowSmall").addClass("jqmWindowLarge");
            }
        }
    }).draggable();
}

/*
 * localized messages
 * XXX: not implemented yet.
*/

function M(message) {
    return message;
}

/* after page load */
jQuery(document).ready(function () {
    init_dialog_window();
});

/************************************************************************
 * map compare
 *
 */

var mc = {
    search: config.search
};

function chooseAddrBTLR(b, t, l, r, lon, lat, message) {
    chooseAddr(l, b, r, t, lon, lat, message)
}

function chooseAddr(l, b, r, t, lon, lat, message) {
    var bounds = new OpenLayers.Bounds(l, b, r, t).transform("EPSG:4326", "EPSG:900913");
    map.zoomToExtent(bounds);
    var zoom = map.zoom;

    if (mc.search.max_zoom && mc.search.max_zoom < zoom) {
        zoom = mc.search.max_zoom;
        debug("reset zoom level for address: " + zoom);
        map.zoomTo(zoom);
    }

    // marker for address
    if (mc.search.show_marker) {
        set_popup({
            "lon": lon,
            "lat": lat,
            "message": message
        });
    }
}

function set_search_width() {
    var width = $(window).width();
    var height = $("div#search-results").outerHeight(true) + $("div#search-form").outerHeight(true);
    var max_with = 760;

    if (width > max_with) {
        width = max_with;
    }
    var help_width = Math.floor(width * 0.95);

    $(".jqmWindow").width(help_width);
    $(".jqmWindow").css("right", 20);

    $(".dialog-search").height(height + 20);
    debug("search help width: " + help_width + " height: " + $(".dialog-search").outerHeight(true));
}

function mc_search(query) {
    if (!query) {
        query = $("input#address-query").attr("value") || "";
    }

    if (mc.search.type == 'nominatim') {
        mc_search_nominatim(query);
    } else {
        debug("unknown search type");
    }
}

function init_search() {
    // $('#address-submit').click(function () {
    // IE8, IE9 submit on enter, see http://support.microsoft.com/kb/298498/
    $('div#search-form form').on('submit', function () {
        mc_search();
        return false;
    });

    // disable keyboard shortcuts on input fields
    $("#search-form").on("focus blur mousein mouseout mouseover", "input#address-query", function () {
        var active = document.activeElement.id == this.id;

        debug("document active: " + (document.activeElement.id ? document.activeElement.id : "ACTIVE") + " " + active);

        // xxx
        if (!state.control || !state.control.keyboard) {
            return;
        }
        active ? state.control.keyboard.deactivate() : state.control.keyboard.activate();
    });

    // copy name of aera into search field, and trigger a search
    if (mc.search.marker_input_field) {
        var query = $("input#" + mc.search.marker_input_field).attr("value");
        if (query != "") {
            $("input#address-query").attr("value", query);
            $('div#search-form form').trigger('submit');
        }
    }

    set_search_width();

    // XXX: on newer jqModal we need a timeout
    setTimeout(function () {
        set_search_width();
    }, 0);

    // XXX: jquery 1.8.3 set the focus later
    // inital focus set
    setTimeout(function () {
        $("div#search-form input#address-query").focus();
    }, 50);
}

function set_popup(obj) {
    if (!obj) return;

    var map = state.map;
    var message = obj.message || "marker";
    var pos = new OpenLayers.LonLat(obj.lon, obj.lat).transform(state.proj4326, map.getProjectionObject());
    debug("set marker: " + obj.lon + "," + obj.lat);


    var message_p = "";
    if (mc.search.marker_permalink) {
        // message_p += '<p/><div><a href="' + $("#permalink").attr("href") + '&marker=' + message + '">permalink</a></div>';
        message_p += '<p/><div><a onclick="click_share_link(' + obj.lon + ',' + obj.lat + ')">share</a></div>';
    }
    if (mc.search.marker_input_field) {
        $("input#" + mc.search.marker_input_field).attr("value", message);
    }

    // A popup with some information about our location
    var popup = new OpenLayers.Popup.FramedCloud("Popup", pos, null, // new OpenLayers.Size(50,50), // null,
    "<span id='mc_popup'>" + message + "</span>" + message_p, null, true // <-- true if we want a close (X) button, false otherwise
    );

    // remove old popups from search clicks
    if (state.popup) {
        map.removePopup(state.popup);
    }

    map.addPopup(popup);

    // keep values for further usage (delete, position)
    state.popup = popup;
    state.marker_message = message;
}

/*
 viewbox=<left>,<top>,<right>,<bottom>
 or viewboxlbrt=<left>,<bottom>,<right>,<top>
   The preferred area to find search results
   */

function get_viewport(map) {
    var proj = map.getProjectionObject();
    var center = map.getCenter().clone();
    var zoom = map.getZoom();

    var box = map.getExtent();
    // 13.184573,52.365721,13.593127,52.66782
    // x1,y1 x2,y2
    var bbox = box.transform(map.getProjectionObject(), state.proj4326).toArray();

    debug(bbox + " " + bbox.length);

    if (bbox && bbox.length == 4) {
        return bbox.join(",");
    } else {
        debug("Warning: no viewboxlbrt found");
        return "";
    }
}

function mc_search_nominatim(query, offset, paging) {
    var limit = mc.search.limit || 25;
    var viewport = "";

    if (!paging) {
        paging = mc.search.paging || 5;
    }
    if (!offset) {
        offset = 0;
    }

    var items = [];
    var counter = 0;


    if (mc.search.viewbox) {
        viewport = get_viewport(map);
    }

    debug("start address search query: " + query + " limit: " + limit + " viewport: " + viewport);
    $("div#search-results").html("<p>start searching...</p>"); // remove old results first
    set_search_width();

    var email = mc.search.user_agent ? "&email=" + mc.search.user_agent : "";

    // async search request to nominatim
    var url = 'https://nominatim.openstreetmap.org/search?format=json&limit=' + limit + "&viewboxlbrt=" + viewport + '&q=' + encodeURI(query) + email;

    // IE8/IE9
    // $.support.cors = false;
    $.getJSON(url, function (data) {
        $("div#search-results").html(""); // remove old results first
        $.each(data, function (index, val) {
            counter++;
            if (index >= offset && index < offset + paging) {
                if (items.length == 0) {
                    $("div#search-results").append("<br/>");
                }
                debug("Address: " + index + ". " + val.display_name + " lat: " + val.lat + " lon: " + val.lon);

                var link = "<p><a title='lat,lon: " + val.lat + "," + val.lon + " [" + val["class"] + "]'";
                link += "href='#' onclick='chooseAddrBTLR(" + val.boundingbox + "," + val.lon + "," + val.lat + ", \"" + val.display_name + "\");return false;'>" + counter + ". " + val.display_name + "</a></p>";
                $("div#search-results").append(link);
                items.push(link);
            }
        });

        // nothing found
        if (items.length == 0) {
            $("div#search-results").append("<p>No results found</p>");
        }

        // probably more results, search again
        else if (items.length == paging && offset + paging < counter) {
            $("div#search-results").append("<hr/><a href='#' onclick='mc_search_nominatim(\"" + query + "\"," + (offset + paging) + ", " + paging + "); return false;'>More results...</a>");
        }

        set_search_width();

    }).fail(function (data, textStatus, error) {
        debug("error nominatim search: " + url);
        debug("error nominatim: data: " + data + ", textStatus: " + textStatus + ", error: " + error);
        $("div#search-results").html("<p>Search with nominatim failed. Please try again later. Sorry!</p>" + "<p>" + error + "</p>");
        set_search_width();
    });
}

/* /cgi/route.cgi */

function gpsies_route(route) {
    debug("start route search: " + route);

    // async request for download json files, to bypass Access-Control-Allow-Origin check
    var url = '/cgi/route.cgi?output=json&route=' + route;

    // https://www.gpsies.com/files/geojson/t/q/w/tqwfwdjuhcjuzjzp.js
    $.getJSON(url, function (data) {
        state.gpsies_data = data; // data.features[0].geometry.coordinates[0];
        plot_line(state.gpsies_data.features[0].geometry.coordinates[0]);
    })

    .fail(function (data, textStatus, error) {
        debug("error route json: " + url);
        debug("error route json: data: " + data + ", textStatus: " + textStatus + ", error: " + error);
    });
}

function plot_line(coords) {
    debug("plot line, length: " + coords.length);

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");
    var points = [];
    for (var i = 0; i < coords.length; i++) {
        var point = new OpenLayers.Geometry.Point(coords[i][0], coords[i][1]);
        point.transform(epsg4326, map.getProjectionObject());
        points.push(point);
    }

    var line_string = new OpenLayers.Geometry.LineString(points);
    var lineFeature = new OpenLayers.Feature.Vector(line_string);

    var style = {
        strokeColor: '#000',
        strokeWidth: 5
    };
    lineFeature.style = style;

    vectors.addFeatures(lineFeature);
}


// EOF
