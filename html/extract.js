/*
 Copyright (c) by http://www.openstreetmap.org/export - OSM License, 2012
 Copyright (c) 2012-2013 Wolfram Schneider, http://bbbike.org
*/

// HTML5: may not work on Android devices!
//"use strict"
// central config
var config = {
    // open help page at start up
    "open_infopage": true,

    // run locate me function at startup
    "locate_me": false,

    // show approx. file size of extract
    "show_filesize": true,

    // city name required
    "city_name_optional": false,

    // limit are size to max. square kilometers
    "max_skm": 24000000,

    // max. area size in MB
    "max_size": {
        "default": 768,
        "obf.zip": 250,
        "navit.zip": 512,
        "garmin-bbbike.zip": 650,
        "garmin-osm.zip": 768,
        "garmin-cycle.zip": 650,
        "garmin-leisure.zip": 650,
        "mapsforge-osm.zip": 100
    },

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

    // plot_default_box();
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


    map.addLayer(new OpenLayers.Layer.OSM("OSM Landscape", ["http://a.tile3.opencyclemap.org/landscape/${z}/${x}/${y}.png", "http://b.tile3.opencyclemap.org/landscape/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        attribution: '<a href="http://www.OpenStreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>, <a href="http://www.opencyclemap.org/">(&copy) OpenCycleMap</a>',
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.OSM.Mapnik("OSM Mapnik", {
        attribution: '<a href="http://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM.CycleMap("OSM CycleMap", {
        attribution: '<a href="http://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>, <a href="http://www.opencyclemap.org/">(&copy) OpenCycleMap</a>'
    }));

    map.addLayer(new OpenLayers.Layer.OSM("OSM Transport", ["http://a.tile2.opencyclemap.org/transport/${z}/${x}/${y}.png", "http://b.tile2.opencyclemap.org/transport/${z}/${x}/${y}.png"], {
        tileOptions: {
            crossOriginKeyword: null
        },
        attribution: '<a href="http://www.openstreetmap.org/copyright">(&copy) OpenStreetMap contributors</a>',
        numZoomLevels: 19
    }));

    map.addLayer(new OpenLayers.Layer.OSM("Esri Topographic", "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/${z}/${y}/${x}.png", {
        attribution: '<a href="http://www.esri.com/">(&copy;) Esri</a>',
        tileOptions: {
            crossOriginKeyword: null
        },
        numZoomLevels: 18
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Physical", {
        type: google.maps.MapTypeId.TERRAIN
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Satellite", {
        type: google.maps.MapTypeId.SATELLITE
    }));

    map.addLayer(new OpenLayers.Layer.Google("Google Map", {
        type: google.maps.MapTypeId.ROADMAP
    }));

    return map;
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

    if ($("select[name=format]").length) {
        $("select[name=format]").change(function () {
            validateControls()
        });
    }
}

function boundsChanged() {
    debug("boundsChanged");

    var epsg4326 = new OpenLayers.Projection("EPSG:4326");

    if (!check_lnglat_form()) {
        alert(M("lng or lat value is out of range -180 ... 180, -90 .. 90"));
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
    if (hostname.match(/^(extract-pro|dev)[2-4]?\.bbbike\.org/i)) {
        config.max_size["default"] *= 2;
        config.max_skm *= 2;
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
}

function plot_default_box_menu_on() {
    polygon_menu(true); // display poygon menu
    polygon_update();
    // switch menu
    $("#drag_box_default").hide();
    $("#drag_box_select").show();
    $("#start_default_box").attr('checked', false);
}

// remove default box from map

function plot_default_box_menu_off() {
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
        alert(ret == 1 ? M("Please fill out all fields!") : M("Use a smaller area! Max size: ") + max_size + "MB");
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
        switch (evt.keyCode) {
        case OpenLayers.Event.KEY_LEFT:
            moveMap(-this.slideFactor, 0);
            break;
        case OpenLayers.Event.KEY_RIGHT:
            moveMap(this.slideFactor, 0);
            break;
        case OpenLayers.Event.KEY_UP:
            moveMap(0, -this.slideFactor);
            break;
        case OpenLayers.Event.KEY_DOWN:
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

/*
	,
        "SanFrancisco": {
            "sw": [-122.9, 37.2],
            "ne": [-121.7, 37.9]
        },
        "NewYork": {
            "sw": [-75, 40.1],
            "ne": [-72.9, 41.1]
        },
        "Copenhagen": {
            "sw": [11.8, 55.4],
            "ne": [13.3, 56]
        }
	*/
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
}

function show_skm(skm, filesize) {
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

    if (skm > config.max_skm) {
        $("#size").html("Max area size: " + config.max_skm + "skm.");
        $("#export_osm_too_large").show();
    } else if (config.max_size[filesize.format] && filesize.size > config.max_size[filesize.format]) {
        // Osmand works only for small areas less than 200MB
        $("#size").html("Max osmand file size: " + config.max_size[filesize.format] + " MB.");
        $("#export_osm_too_large").show();
    } else if (filesize.size > config.max_size["default"]) {
        $("#size").html("Max file size: " + config.max_size["default"] + " MB.");
        $("#export_osm_too_large").show();
    } else {
        $("#export_osm_too_large").hide();
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
            var p = polygon + (1 - polygon) * (size > 300000 ? 0.5 : 0.3);
            debug("reset polygon of size: " + size + " from polygon: " + polygon + " to: " + p);
            polygon = p;
        }

        var filesize = show_filesize(skm * polygon, size * polygon);
        show_skm(skm * polygon, filesize);
    });
}

function show_filesize(skm, real_size) {
    var extract_time = 800; // standard extract time in seconds for PBF
    var format = $("select[name=format] option:selected").val();
    var size = real_size ? real_size / 1024 : 0;
    debug("show filesize skm: " + parseInt(skm) + " size: " + Math.round(size) + "MB " + format);

    // all formats *must* be configured
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
            "time": 2
        },
        "garmin-cycle.zip": {
            "size": 0.8,
            "time": 2
        },
        "garmin-leisure.zip": {
            "size": 0.9,
            "time": 3
        },
        "garmin-bbbike.zip": {
            "size": 0.8,
            "time": 2
        },
        "shp.zip": {
            "size": 1.5
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
        "mapsforge-osm.zip": {
            "size": 0.8,
            "time": 14
        },
        "navit.zip": {
            "size": 0.8
        }
    };

    if (!filesize[format]) {
        debug("Unknwon format: " + format);
    }

    var factor = filesize[format].size ? filesize[format].size : 1;
    var factor_time = filesize[format].time ? filesize[format].time : 1;

    var time_min = extract_time + 0.6 * size + (size * factor_time);
    var time_max = extract_time + 0.6 * size + (size * factor_time * 2);

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

/* localized messages */

function M(message) {
    return message;
}

/* after page load */
jQuery(document).ready(function () {
    init_dialog_window();
});

// EOF
